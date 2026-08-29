"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.enforceRetention = void 0;
const scheduler_1 = require("firebase-functions/v2/scheduler");
const firestore_1 = require("firebase-admin/firestore");
/**
 * Data retention (Â§6 cost control, Â§7 data handling).
 *
 * Several collections here are append-only by design, which means without this
 * they grow without bound. Two of them are worse than merely expensive:
 *
 * - `otp_requests` is queried with `count()` over a 24-hour window on every
 *   OTP request. Old rows are not just storage, they are read cost on a hot
 *   path, and the query slows as the collection grows.
 * - `buy_now_taps` accumulates one document per tap per Reel. A Reel that does
 *   well produces tens of thousands, and the funnel job recounted the whole
 *   subcollection every thirty minutes â€” a cost that rises quadratically with
 *   success, which is exactly the wrong shape.
 *
 * The policy below is deliberate about what it does NOT delete. Moderation
 * records and completed orders are kept: one is the evidence behind a decision
 * someone may appeal, the other is a shared commercial record the seller has
 * lawful basis to retain. Deleting either to save storage would be trading
 * something that matters for something that costs pennies.
 */
/** Retention windows, in days. Named so the policy is readable in one place. */
const RETENTION = {
    /** Guard only looks back 24h; 3 days leaves margin for clock skew and backfill. */
    otpRequests: 3,
    /** Promo attempt records. The throttle only looks back an hour. */
    promoAttempts: 2,
    /** Duplicate reports folded into a primary entry. The primary is kept. */
    mergedReports: 30,
    /** Resolved reports. Long enough to handle an appeal, short enough to forget. */
    resolvedReports: 180,
    /** Audit log. Kept far longer â€” it is the record of decisions, not the data. */
    moderationLog: 730,
    /**
     * Idempotency keys, including webhook replay markers.
     *
     * Client retries happen within minutes. Provider webhook retries can span
     * hours, and a provider replaying a week-old event should still be
     * deduplicated rather than reapplied, so this window is set by the slowest
     * retry policy rather than the fastest.
     */
    idempotencyKeys: 30,
};
const MAX_DELETES_PER_RUN = 5000;
exports.enforceRetention = (0, scheduler_1.onSchedule)(
// Nightly, off the half-hour so it never overlaps the materialisation sweeps.
{ schedule: "17 3 * * *", timeoutSeconds: 540 }, async () => {
    const db = (0, firestore_1.getFirestore)();
    await Promise.all([
        pruneByAge(db, "otp_requests", "created_at", RETENTION.otpRequests),
        // The collection is `idempotency_keys`. It was written here as
        // `idempotency` for a while, so the job quietly pruned nothing while the
        // real ledger grew â€” a name mismatch that looks correct on both sides.
        pruneByAge(db, "idempotency_keys", "created_at", RETENTION.idempotencyKeys),
        pruneByAge(db, "moderation_log", "created_at", RETENTION.moderationLog),
        pruneGroupByAge(db, "attempts", "at", RETENTION.promoAttempts),
        pruneReports(db),
        eraseDeliveryDetails(db),
    ]);
});
/**
 * Deletes documents in [collection] older than [days].
 *
 * Capped per run rather than looping until empty. A cleanup job that tries to
 * delete a million documents in one invocation times out halfway and leaves the
 * collection in the same state next time; a capped job that runs nightly
 * converges instead, and its cost is predictable.
 */
async function pruneByAge(db, collection, field, days) {
    const cutoff = firestore_1.Timestamp.fromMillis(Date.now() - days * 24 * 60 * 60 * 1000);
    let deleted = 0;
    while (deleted < MAX_DELETES_PER_RUN) {
        const page = await db
            .collection(collection)
            .where(field, "<", cutoff)
            .limit(400)
            .get();
        if (page.empty)
            break;
        const batch = db.batch();
        for (const doc of page.docs)
            batch.delete(doc.ref);
        await batch.commit();
        deleted += page.size;
        if (page.size < 400)
            break;
    }
    return deleted;
}
/**
 * Same as [pruneByAge] but across a collection GROUP.
 *
 * Promo attempts live under `promo_attempts/{uid}/attempts`, one subcollection
 * per person, so there is no single collection to sweep. A group query reaches
 * all of them at once â€” which is also why the cap matters more here: the sweep
 * spans every user rather than one document tree.
 */
async function pruneGroupByAge(db, group, field, days) {
    const cutoff = firestore_1.Timestamp.fromMillis(Date.now() - days * 24 * 60 * 60 * 1000);
    let deleted = 0;
    while (deleted < MAX_DELETES_PER_RUN) {
        const page = await db
            .collectionGroup(group)
            .where(field, "<", cutoff)
            .limit(400)
            .get();
        if (page.empty)
            break;
        const batch = db.batch();
        for (const doc of page.docs)
            batch.delete(doc.ref);
        await batch.commit();
        deleted += page.size;
        if (page.size < 400)
            break;
    }
}
/**
 * Finishes erasing delivery details for buyers who deleted their account while
 * an order was still in flight.
 *
 * The cascade leaves those in place deliberately â€” a courier is mid-delivery,
 * and erasing the address does not protect anyone, it only strands the seller
 * with an order they cannot complete. Once the order reaches a terminal state
 * the details serve nobody, and this removes them.
 *
 * Runs nightly, so the window between "order completed" and "pin erased" is at
 * most a day. That is the honest number, and the deletion copy says so.
 */
async function eraseDeliveryDetails(db) {
    const pending = await db
        .collection("orders")
        .where("delivery_details_pending_erasure", "==", true)
        .limit(400)
        .get();
    if (pending.empty)
        return;
    const terminal = new Set(["delivered", "cancelled", "refunded"]);
    const batch = db.batch();
    let queued = 0;
    for (const order of pending.docs) {
        if (!terminal.has(order.get("status")))
            continue;
        batch.update(order.ref, {
            buyer_phone: firestore_1.FieldValue.delete(),
            address_id: firestore_1.FieldValue.delete(),
            delivery_address: firestore_1.FieldValue.delete(),
            delivery_location: firestore_1.FieldValue.delete(),
            delivery_details_pending_erasure: firestore_1.FieldValue.delete(),
        });
        queued += 1;
    }
    if (queued > 0)
        await batch.commit();
}
/**
 * Reports, by state rather than by age alone.
 *
 * A pending report is never deleted no matter how old â€” an unreviewed report
 * ageing out would silently clear the queue, which is the opposite of what a
 * queue is for.
 */
async function pruneReports(db) {
    const mergedCutoff = firestore_1.Timestamp.fromMillis(Date.now() - RETENTION.mergedReports * 24 * 60 * 60 * 1000);
    const resolvedCutoff = firestore_1.Timestamp.fromMillis(Date.now() - RETENTION.resolvedReports * 24 * 60 * 60 * 1000);
    const merged = await db
        .collection("reports")
        .where("action", "==", "merged")
        .where("created_at", "<", mergedCutoff)
        .limit(400)
        .get();
    if (!merged.empty) {
        const batch = db.batch();
        for (const doc of merged.docs)
            batch.delete(doc.ref);
        await batch.commit();
    }
    // Resolved reports go one state at a time rather than with `not-in`, which
    // Firestore caps at ten values and cannot combine with a range filter.
    for (const state of ["dismissed", "contentRemoved", "accountWarned"]) {
        const page = await db
            .collection("reports")
            .where("action", "==", state)
            .where("reviewed_at", "<", resolvedCutoff)
            .limit(200)
            .get();
        if (page.empty)
            continue;
        const batch = db.batch();
        for (const doc of page.docs)
            batch.delete(doc.ref);
        await batch.commit();
    }
    // `accountSuspended` is deliberately absent from that list. A suspension is
    // the decision most likely to be appealed months later, and the report is the
    // only record of what prompted it. The audit log entry survives regardless,
    // but the report carries the reason.
}
//# sourceMappingURL=retention.js.map
