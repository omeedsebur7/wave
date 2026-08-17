"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.materializeCounters = void 0;
const scheduler_1 = require("firebase-functions/v2/scheduler");
const firestore_1 = require("firebase-admin/firestore");
/**
 * Materialise sharded counters onto the parent document (Â§6).
 *
 * Reading a sharded counter properly means an aggregation query per Reel. In a
 * feed of 8 Reels that's 8 extra round-trips before anything renders. So a
 * scheduled job sums the shards and writes the total back onto the Reel, and
 * the feed reads one field.
 *
 * The trade-off is deliberate: like counts are eventually consistent, up to the
 * schedule interval stale. That is fine â€” nobody notices a like count that is
 * 30 seconds behind, and the user's OWN like appears instantly via the
 * optimistic client update.
 */
/// Runs on the 5s, ahead of both half-hourly sweeps, so the like and view
/// totals rankFeed reads are as fresh as they can be when it scores.
exports.materializeCounters = (0, scheduler_1.onSchedule)({ schedule: "*/5 * * * *" }, async () => {
    const db = (0, firestore_1.getFirestore)();
    const reels = await db
        .collection("reels")
        .where("status", "==", "published")
        .orderBy("created_at", "desc")
        .limit(2000)
        .get();
    let batch = db.batch();
    let ops = 0;
    for (const reel of reels.docs) {
        const [likes, views] = await Promise.all([
            sumShards(reel.ref, "likes"),
            sumShards(reel.ref, "views"),
        ]);
        batch.update(reel.ref, { likes_count: likes, views_count: views });
        if (++ops >= 450) {
            await batch.commit();
            batch = db.batch();
            ops = 0;
        }
    }
    if (ops > 0)
        await batch.commit();
});
async function sumShards(parent, counterName) {
    const agg = await parent.collection(`counters_${counterName}`).get();
    return agg.docs.reduce((sum, d) => sum + (d.get("count") ?? 0), 0);
}
//# sourceMappingURL=materializeShards.js.map