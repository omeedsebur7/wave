"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.dedupeReport = exports.liftSuspension = exports.resolveReport = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-functions/v2/firestore");
const auth_1 = require("firebase-admin/auth");
const firestore_2 = require("firebase-admin/firestore");
/**
 * Records a moderation decision and applies its consequence (Â§4).
 *
 * Routed through a function rather than a client write for three reasons:
 * removing content and suspending accounts need Admin-SDK privileges the client
 * must never hold; the decision and the action it authorises have to land
 * together or not at all; and every decision needs an audit entry naming who
 * made it.
 */
exports.resolveReport = (0, https_1.onCall)({ cors: true }, async (request) => {
    // Checked here as well as in Security Rules. The rules stop a direct
    // Firestore read of the queue; this stops a direct call to the function.
    if (request.auth?.token?.moderator !== true) {
        throw new https_1.HttpsError("permission-denied", "Moderators only");
    }
    const db = (0, firestore_2.getFirestore)();
    const moderatorId = request.auth.uid;
    const reportId = String(request.data?.reportId ?? "");
    const action = String(request.data?.action ?? "");
    const note = request.data?.note ? String(request.data.note) : null;
    const allowed = [
        "dismissed",
        "contentRemoved",
        "accountWarned",
        "accountSuspended",
    ];
    if (!allowed.includes(action)) {
        throw new https_1.HttpsError("invalid-argument", "Unknown action");
    }
    const reportRef = db.collection("reports").doc(reportId);
    // The whole read-check-write sequence lives in ONE transaction.
    //
    // It did not, until now. The status was read with a plain `.get()`, checked,
    // and then â€” after `resolveOwner`'s own `.get()` calls and up to about eighty
    // lines of code later â€” written with an unconditional `WriteBatch`. The
    // comment beside the original check ("a race worth losing loudly") shows the
    // author knew two moderators could hit this at once; the code just did not
    // stop it. A batch commits unconditionally, so two moderators resolving the
    // same report within that window would both pass the `pending` check, both
    // proceed, and whichever commit landed last would silently overwrite the
    // other's decision on the report â€” while the audit log, which allocates a new
    // document per call rather than reusing one, would end up with an entry for
    // BOTH actions. An audit log that records two decisions when only one took
    // effect is worse than no audit log, because it looks authoritative.
    //
    // Two Admin Auth calls below (`setCustomUserClaims`, `revokeRefreshTokens`)
    // cannot go inside the transaction â€” Firestore can retry a transaction body,
    // and an Auth API call is not something Firestore can roll back or safely
    // re-run. So they stay outside, gated on the transaction's own result: they
    // only run if this specific call is the one that actually won the report.
    const { suspendedUid } = await db.runTransaction(async (tx) => {
        const report = await tx.get(reportRef);
        if (!report.exists) {
            throw new https_1.HttpsError("not-found", "Report not found");
        }
        if (report.get("action") !== "pending") {
            throw new https_1.HttpsError("aborted", "Already reviewed by someone else");
        }
        const targetType = report.get("target_type");
        const targetId = report.get("target_id");
        if (action === "contentRemoved") {
            // A status change, not a delete. Removed content still has to be
            // visible to an appeal, and deleting it would destroy the evidence the
            // decision rested on.
            const collection = targetType === "reel"
                ? "reels"
                : targetType === "product"
                    ? "products"
                    : null;
            if (collection) {
                tx.update(db.collection(collection).doc(targetId), {
                    status: "removed",
                    removed_at: firestore_2.FieldValue.serverTimestamp(),
                    removed_by: moderatorId,
                });
            }
        }
        let suspendedUid = null;
        if (action === "accountSuspended" || action === "accountWarned") {
            // Reads through `tx`, not a bare `.get()` â€” Firestore requires every
            // read in a transaction to happen before any write, and a read that
            // bypassed `tx` would not be covered by the transaction's conflict
            // detection at all, silently reopening the exact race this rewrite
            // exists to close.
            const ownerId = await resolveOwner(tx, db, targetType, targetId);
            if (ownerId) {
                tx.set(db.collection("users").doc(ownerId), action === "accountSuspended"
                    ? {
                        suspended: true,
                        suspended_at: firestore_2.FieldValue.serverTimestamp(),
                    }
                    : {
                        warning_count: firestore_2.FieldValue.increment(1),
                        last_warned_at: firestore_2.FieldValue.serverTimestamp(),
                    }, { merge: true });
                if (action === "accountSuspended")
                    suspendedUid = ownerId;
            }
        }
        tx.update(reportRef, {
            action,
            note,
            reviewed_by: moderatorId,
            reviewed_at: firestore_2.FieldValue.serverTimestamp(),
        });
        // Append-only audit log, separate from the report itself. A moderation
        // decision that can be edited afterwards is not a record of anything.
        //
        // Writing it inside the same transaction as the report update is what
        // makes "append-only" actually true: the log entry and the decision it
        // describes now commit together or not at all, so a lost race no longer
        // produces a log entry for a decision that did not stick.
        tx.set(db.collection("moderation_log").doc(), {
            report_id: reportId,
            target_type: targetType,
            target_id: targetId,
            action,
            note,
            moderator_id: moderatorId,
            created_at: firestore_2.FieldValue.serverTimestamp(),
        });
        return { targetType, targetId, suspendedUid };
    });
    // Enforcement, not just a flag.
    //
    // The Firestore document is what the app reads to explain itself; the CLAIM
    // is what Security Rules check, because a claim travels in the token and
    // costs no read on every write. Setting one without the other would produce
    // a suspension that either is unenforceable or cannot be explained.
    if (suspendedUid) {
        await (0, auth_1.getAuth)().setCustomUserClaims(suspendedUid, { suspended: true });
        // A claim only reaches the device on the next token refresh â€” up to an
        // hour. Revoking forces re-authentication immediately, so a suspension
        // takes effect now rather than whenever the token happens to roll over.
        await (0, auth_1.getAuth)().revokeRefreshTokens(suspendedUid);
    }
    return { ok: true };
});
/**
 * Lifts a suspension.
 *
 * Separate callable rather than an "unsuspend" action on a report, because
 * reinstatement is an appeal outcome and does not belong to whichever report
 * originally triggered the suspension.
 */
exports.liftSuspension = (0, https_1.onCall)({ cors: true }, async (request) => {
    if (request.auth?.token?.moderator !== true) {
        throw new https_1.HttpsError("permission-denied", "Moderators only");
    }
    const uid = String(request.data?.uid ?? "");
    if (!uid)
        throw new https_1.HttpsError("invalid-argument", "Missing uid");
    const db = (0, firestore_2.getFirestore)();
    await (0, auth_1.getAuth)().setCustomUserClaims(uid, { suspended: null });
    await db.collection("users").doc(uid).set({
        suspended: false,
        suspension_lifted_at: firestore_2.FieldValue.serverTimestamp(),
    }, { merge: true });
    await db.collection("moderation_log").add({
        target_type: "profile",
        target_id: uid,
        action: "suspensionLifted",
        moderator_id: request.auth.uid,
        created_at: firestore_2.FieldValue.serverTimestamp(),
    });
    return { ok: true };
});
async function resolveOwner(tx, db, targetType, targetId) {
    switch (targetType) {
        case "reel": {
            // Read through `tx`, not a bare `.get()`. A read outside the transaction
            // is invisible to its conflict detection â€” it would not be retried if
            // the document changed underneath it, and (since Firestore requires all
            // transaction reads before any write) mixing the two read styles risks
            // an ordering violation the SDK will reject at runtime.
            const doc = await tx.get(db.collection("reels").doc(targetId));
            return doc.get("author_id") ?? null;
        }
        case "product": {
            const doc = await tx.get(db.collection("products").doc(targetId));
            return doc.get("seller_id") ?? null;
        }
        case "profile":
            return targetId;
        default:
            return null;
    }
}
/**
 * Collapses repeat reports on the same target onto one queue entry.
 *
 * Without this, eight people reporting the same Reel produces eight queue
 * items, and a moderator dismisses the same thing eight times â€” which both
 * wastes the scarcest resource in moderation and buries the signal that eight
 * separate people objected.
 */
exports.dedupeReport = (0, firestore_1.onDocumentCreated)("reports/{reportId}", async (event) => {
    const db = (0, firestore_2.getFirestore)();
    const data = event.data;
    if (!data)
        return;
    const targetId = data.get("target_id");
    const targetType = data.get("target_type");
    if (!targetId || !targetType)
        return;
    const existing = await db
        .collection("reports")
        .where("target_id", "==", targetId)
        .where("target_type", "==", targetType)
        .where("action", "==", "pending")
        .orderBy("created_at")
        .limit(1)
        .get();
    const primary = existing.docs[0];
    if (!primary || primary.id === event.params.reportId) {
        // First open report on this target; it becomes the entry others fold in.
        return;
    }
    await db.runTransaction(async (tx) => {
        tx.update(primary.ref, {
            report_count: firestore_2.FieldValue.increment(1),
        });
        // The duplicate keeps its reporter_id â€” needed if a reporter turns out to
        // be filing in bad faith â€” but leaves the queue.
        tx.update(data.ref, { action: "merged", merged_into: primary.id });
    });
});
//# sourceMappingURL=resolveReport.js.map
