"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.materializeReelFunnel = exports.onReviewWritten = exports.onProductWritten = exports.onReelWritten = exports.onFollowChanged = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const scheduler_1 = require("firebase-functions/v2/scheduler");
const firestore_2 = require("firebase-admin/firestore");
/**
 * Materialises the counts shown on a profile.
 *
 * These are written by a function rather than incremented by the client for the
 * same reason `phone_verified` is: a client that can set its own follower count
 * can fake reach, and reach is what sponsorship pricing will key off in Phase 2.
 */
exports.onFollowChanged = (0, firestore_1.onDocumentWritten)("users/{uid}/following/{sellerId}", async (event) => {
    const sellerId = event.params.sellerId;
    const db = (0, firestore_2.getFirestore)();
    // Recount rather than increment. An incremental counter drifts on every
    // failed retry, and a follower count that slowly diverges from reality is
    // very hard to notice and very embarrassing to explain.
    const followers = await db
        .collectionGroup("following")
        .where(firestore_2.FieldPath.documentId(), "==", sellerId)
        .count()
        .get();
    await db.collection("users").doc(sellerId).set({ follower_count: followers.data().count }, { merge: true });
});
/**
 * Keeps `reel_count` on a seller profile current.
 *
 * Read by the profile screen. Without this it renders zero for everyone, which
 * makes an active seller look like they have never posted.
 */
exports.onReelWritten = (0, firestore_1.onDocumentWritten)("reels/{reelId}", async (event) => {
    const authorId = event.data?.after?.get("author_id") ?? event.data?.before?.get("author_id");
    if (!authorId)
        return;
    const db = (0, firestore_2.getFirestore)();
    const count = await db
        .collection("reels")
        .where("author_id", "==", authorId)
        .where("status", "==", "published")
        .count()
        .get();
    await db.collection("users").doc(authorId).set({ reel_count: count.data().count }, { merge: true });
});
exports.onProductWritten = (0, firestore_1.onDocumentWritten)("products/{productId}", async (event) => {
    const sellerId = event.data?.after?.get("seller_id") ?? event.data?.before?.get("seller_id");
    if (!sellerId)
        return;
    const db = (0, firestore_2.getFirestore)();
    const count = await db
        .collection("products")
        .where("seller_id", "==", sellerId)
        .where("status", "==", "active")
        .count()
        .get();
    await db.collection("users").doc(sellerId).set({ product_count: count.data().count }, { merge: true });
});
/**
 * Keeps a product's rating average AND its full star distribution current.
 *
 * The distribution matters: a 4.0 made of all 4s and a 4.0 made of half 5s and
 * half 3s describe very different products, and showing only the mean hides
 * that from the buyer.
 */
exports.onReviewWritten = (0, firestore_1.onDocumentWritten)("reviews/{reviewId}", async (event) => {
    const productId = event.data?.after?.get("product_id") ?? event.data?.before?.get("product_id");
    if (!productId)
        return;
    const db = (0, firestore_2.getFirestore)();
    const reviews = await db
        .collection("reviews")
        .where("product_id", "==", productId)
        .get();
    const distribution = {
        "1": 0, "2": 0, "3": 0, "4": 0, "5": 0,
    };
    let sum = 0;
    for (const doc of reviews.docs) {
        const rating = Number(doc.get("rating") ?? 0);
        if (rating >= 1 && rating <= 5) {
            distribution[String(rating)] += 1;
            sum += rating;
        }
    }
    const count = reviews.size;
    await db.collection("products").doc(productId).set({
        rating_avg: count === 0 ? 0 : Number((sum / count).toFixed(2)),
        rating_count: count,
        rating_distribution: distribution,
    }, { merge: true });
});
/**
 * Materialises the per-Reel funnel counters the seller dashboard reads.
 *
 * These live on the Reel document rather than being queried from Firebase
 * Analytics, because Analytics is sampled, delayed by hours, and cannot be
 * queried per-seller from a client. Analytics stays the tool for product-wide
 * questions; a seller asking about their own Reel needs an answer from their
 * own data.
 *
 * Buy Now taps are written by the client to a subcollection (append-only,
 * rate-limited by rules) and summed here, for the same reason like counts are
 * sharded: a popular Reel would otherwise exceed the one-write-per-second
 * ceiling on a single document.
 */
exports.materializeReelFunnel = (0, scheduler_1.onSchedule)(
// Offset from rankFeed, which also runs every 30 minutes and also writes to
// every published Reel. Overlapping sweeps would contend on the same
// documents and, worse, rankFeed could read a half-updated funnel count and
// rank on it.
{ schedule: "10,40 * * * *", timeoutSeconds: 540 }, async () => {
    const db = (0, firestore_2.getFirestore)();
    const reels = await db
        .collection("reels")
        .where("status", "==", "published")
        .orderBy("created_at", "desc")
        .limit(2000)
        .get();
    for (const reel of reels.docs) {
        await consumeTaps(db, reel.ref);
        // Orders are still counted rather than consumed: unlike taps, order
        // documents are the permanent commercial record and cannot be deleted
        // after summing. The count is cheap because orders per Reel are orders of
        // magnitude fewer than taps.
        const orders = await db
            .collection("orders")
            .where("source_reel_id", "==", reel.id)
            .count()
            .get();
        await reel.ref.update({ orders_count: orders.data().count });
    }
});
/**
 * Sums new Buy Now taps into a running total and deletes the documents it
 * counted.
 *
 * The previous version recounted the entire subcollection every thirty minutes.
 * That is the wrong shape: a Reel that does well accumulates tens of thousands
 * of tap documents, and the cost of measuring its success rose with that
 * success, forever, whether or not anyone looked at the number.
 *
 * Consuming instead means the subcollection stays small and the total is exact.
 * The increment and the deletes go in ONE batch â€” if they were separate, a crash
 * between them would either lose taps (deleted but not counted) or double-count
 * them (counted but not deleted) on the next run. Batched, a crash before commit
 * leaves the taps in place to be counted next time, which is the safe direction
 * to fail.
 */
async function consumeTaps(db, reelRef) {
    // Bounded per run per Reel. A single viral Reel must not starve the other
    // 1,999 in the sweep; the remainder is picked up on the next pass.
    const taps = await reelRef.collection("buy_now_taps").limit(400).get();
    if (taps.empty)
        return;
    const batch = db.batch();
    batch.update(reelRef, {
        buy_now_taps: firestore_2.FieldValue.increment(taps.size),
    });
    for (const tap of taps.docs)
        batch.delete(tap.ref);
    await batch.commit();
}
//# sourceMappingURL=profileStats.js.map