"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.unlinkWithdrawnProduct = exports.unlinkDeletedProduct = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const firestore_2 = require("firebase-admin/firestore");
/**
 * Keeps `linked_product_id` on Reels pointing at something that exists (Â§5.1).
 *
 * A seller may delete a listing at any time, and Security Rules correctly let
 * them. Nothing propagated that to the Reels linked to it, so the Reel kept a
 * Buy Now button aimed at a document that was gone.
 *
 * The consequence lands on the single most important path in the app: someone
 * watches a Reel, decides to buy, taps, and the sheet has nothing to show. That
 * reads as a broken app rather than a withdrawn listing, and it happens to the
 * people furthest along the funnel â€” the ones who already decided.
 *
 * Removing the link is the right repair rather than removing the Reel. The video
 * is the seller's content and may be worth watching on its own; only the promise
 * of a purchase is no longer true.
 */
exports.unlinkDeletedProduct = (0, firestore_1.onDocumentDeleted)("products/{productId}", async (event) => {
    await unlinkFromReels(event.params.productId);
});
/**
 * Also unlinks when a listing is withdrawn rather than deleted.
 *
 * `status: 'removed'` is what moderation sets, and a Reel still advertising a
 * product a moderator took down is worse than one advertising a deleted one.
 */
exports.unlinkWithdrawnProduct = (0, firestore_1.onDocumentUpdated)("products/{productId}", async (event) => {
    const before = event.data?.before;
    const after = event.data?.after;
    if (!before || !after)
        return;
    if (before.get("status") !== after.get("status") &&
        after.get("status") === "removed") {
        await unlinkFromReels(event.params.productId);
        return;
    }
    // Price changes propagate to the Buy Now button.
    //
    // The price is denormalised onto the Reel so the feed can render a figure
    // without a read per card. That is only safe if something keeps it current
    // â€” a stale price on the button means someone taps "Buy Now â€” 25,000" and
    // the sheet says 40,000, which reads as a bait-and-switch even when it is
    // an honest edit.
    //
    // Nothing is ever charged from this number: the sheet re-reads the product
    // and `placeOrder` recomputes again. It exists so the button can be honest,
    // not so the order can be cheap.
    const priceChanged = before.get("price_minor") !== after.get("price_minor") ||
        before.get("currency") !== after.get("currency");
    if (priceChanged) {
        await syncPriceToReels(event.params.productId, after.get("price_minor"), after.get("currency"));
    }
});
/**
 * Also runs when a product is first linked, via the publish path â€” see
 * `publishReel`, which writes the price alongside the link.
 */
async function syncPriceToReels(productId, priceMinor, currency) {
    const db = (0, firestore_2.getFirestore)();
    const reels = await db
        .collection("reels")
        .where("linked_product_id", "==", productId)
        .get();
    if (reels.empty)
        return;
    const batch = db.batch();
    for (const reel of reels.docs) {
        batch.update(reel.ref, {
            linked_product_price_minor: priceMinor,
            linked_product_currency: currency,
        });
    }
    await batch.commit();
}
async function unlinkFromReels(productId) {
    const db = (0, firestore_2.getFirestore)();
    const reels = await db
        .collection("reels")
        .where("linked_product_id", "==", productId)
        .get();
    if (reels.empty)
        return;
    const batch = db.batch();
    for (const reel of reels.docs) {
        batch.update(reel.ref, {
            // Deleted rather than nulled, so `linked_product_id != null` stays a
            // reliable test for "this Reel can be bought from" everywhere it is used.
            linked_product_id: firestore_2.FieldValue.delete(),
            // The display price goes with the link. Leaving it would put a price on a
            // Reel with nothing to buy.
            linked_product_price_minor: firestore_2.FieldValue.delete(),
            linked_product_currency: firestore_2.FieldValue.delete(),
            // Kept as a breadcrumb. A seller wondering why their Reel lost its Buy Now
            // button deserves an answer, and support cannot reconstruct it from a
            // field that simply vanished.
            unlinked_product_id: productId,
            unlinked_at: firestore_2.FieldValue.serverTimestamp(),
        });
    }
    await batch.commit();
}
//# sourceMappingURL=unlinkProduct.js.map
