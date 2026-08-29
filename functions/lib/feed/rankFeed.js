"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.rankFeed = void 0;
const scheduler_1 = require("firebase-functions/v2/scheduler");
const firestore_1 = require("firebase-admin/firestore");
const feedRanking_1 = require("../domain/feedRanking");
/**
 * Feed ranking heuristic (Â§4).
 *
 * An explicit non-goal for Phase 1 is a real recommendation model. This only
 * has to beat "no ranking at all", which it does for almost nothing â€” and it's
 * what makes the Buy-Now conversion funnel worth optimising once Phase 2 data
 * arrives.
 *
 *   score = engagementRate * recencyDecay
 *
 * Engagement RATE rather than raw count, or a Reel from launch week with 50k
 * views outranks everything new forever and the feed calcifies. Recency decay
 * is exponential with a 48h half-life: fast enough to keep the feed alive, slow
 * enough that a genuinely good Reel gets more than a day of reach.
 *
 * Computed on a schedule, not per-read: ranking at query time would need a
 * composite index on a value that changes constantly, which Firestore handles
 * badly and bills for heavily.
 */
exports.rankFeed = (0, scheduler_1.onSchedule)({ schedule: "0,30 * * * *" }, async () => {
    const db = (0, firestore_1.getFirestore)();
    // Only rank what's plausibly still in circulation. Re-scoring the entire
    // archive every 30 minutes would dominate the bill for no benefit.
    const cutoff = firestore_1.Timestamp.fromMillis(Date.now() - 1000 * 60 * 60 * 24 * 14);
    const snap = await db
        .collection("reels")
        .where("status", "==", "published")
        .where("created_at", ">", cutoff)
        .get();
    const now = Date.now();
    let batch = db.batch();
    let opsInBatch = 0;
    for (const doc of snap.docs) {
        const createdAt = doc.get("created_at")?.toMillis() ?? now;
        batch.update(doc.ref, {
            rank_score: (0, feedRanking_1.rankScore)({
                likes: doc.get("likes_count") ?? 0,
                comments: doc.get("comments_count") ?? 0,
                views: doc.get("views_count") ?? 0,
                createdAtMs: createdAt,
                authorIsPopular: (doc.get("author_follower_count") ?? 0) > 100,
            }, now),
        });
        // Firestore caps a batch at 500 writes.
        if (++opsInBatch >= 450) {
            await batch.commit();
            batch = db.batch();
            opsInBatch = 0;
        }
    }
    if (opsInBatch > 0)
        await batch.commit();
});
//# sourceMappingURL=rankFeed.js.map
