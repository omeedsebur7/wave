"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.recomputeTrustTier = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const firestore_2 = require("firebase-admin/firestore");
const remote_config_1 = require("firebase-admin/remote-config");
const trustTier_1 = require("../domain/trustTier");
/**
 * Seller trust tier (Â§5.2 / Â§3.7).
 *
 * Thresholds come from Remote Config, never from constants in this file â€” the
 * brief is explicit that they're starting numbers to be tuned once real order
 * volume exists, and a hardcoded threshold means a code deploy to change a
 * business rule.
 *
 * Runs on every seller_ratings write. Aggregates are recomputed rather than
 * incrementally adjusted: an incremental average drifts as ratings are added
 * and corrected, and a wrong trust badge is worse than a slightly slower
 * function.
 */
exports.recomputeTrustTier = (0, firestore_1.onDocumentWritten)("seller_ratings/{ratingId}", async (event) => {
    const db = (0, firestore_2.getFirestore)();
    const sellerId = event.data?.after?.get("seller_id") ?? event.data?.before?.get("seller_id");
    if (!sellerId)
        return;
    const [ratings, deliveredOrders, sellerCancellations, thresholds] = await Promise.all([
        db.collection("seller_ratings").where("seller_id", "==", sellerId).get(),
        db
            .collection("orders")
            .where("seller_id", "==", sellerId)
            .where("status", "==", "delivered")
            .count()
            .get(),
        // Counted separately from buyer cancellations. A buyer changing their
        // mind says nothing about the seller, and folding the two together
        // would penalise sellers for their customers' behaviour â€” which would
        // make the tier reflect luck rather than reliability.
        db
            .collection("orders")
            .where("seller_id", "==", sellerId)
            .where("status", "==", "cancelled")
            .where("cancelled_by", "==", "seller")
            .count()
            .get(),
        loadThresholds(),
    ]);
    const aggregate = (0, trustTier_1.aggregateRatings)(ratings.docs.map((d) => Number(d.get("rating") ?? 0)));
    const completedOrders = deliveredOrders.data().count;
    const cancelledBySeller = sellerCancellations.data().count;
    const tier = (0, trustTier_1.tierFor)(completedOrders, aggregate.average, thresholds, cancelledBySeller);
    await db.collection("users").doc(sellerId).set({
        avg_rating: aggregate.average,
        rating_count: aggregate.count,
        completed_orders: completedOrders,
        // Stored so the seller can see the number the gate is reading. A tier
        // that drops for reasons nobody can inspect is a tier people distrust.
        seller_cancellations: cancelledBySeller,
        trust_tier: tier,
        trust_updated_at: firestore_2.FieldValue.serverTimestamp(),
    }, { merge: true });
    await fanOutTierToListings(db, sellerId, tier);
});
/**
 * Copies the tier onto every one of the seller's listings.
 *
 * The tier is denormalised onto product documents so a grid of twenty products
 * can draw twenty trust badges without twenty extra reads of the seller
 * profile. That denormalisation is only worth anything if something keeps it
 * current â€” otherwise every product card shows no badge forever, however
 * trusted the seller becomes, and the entire tier system is invisible exactly
 * where a buyer is deciding.
 *
 * Also fans out on Reels, for the same reason on the Buy Now sheet.
 */
async function fanOutTierToListings(db, sellerId, tier) {
    const seller = await db.collection("users").doc(sellerId).get();
    const kycVerified = seller.get("kyc_verified") === true;
    for (const collection of ["products", "reels"]) {
        const field = collection === "products" ? "seller_id" : "author_id";
        let last;
        for (;;) {
            let query = db
                .collection(collection)
                .where(field, "==", sellerId)
                .orderBy(firestore_2.FieldPath.documentId())
                .limit(400);
            if (last)
                query = query.startAfter(last);
            const page = await query.get();
            if (page.empty)
                break;
            const batch = db.batch();
            for (const doc of page.docs) {
                batch.update(doc.ref, {
                    seller_tier: tier,
                    seller_kyc_verified: kycVerified,
                });
            }
            await batch.commit();
            // Paged rather than fetched whole: a seller with thousands of listings
            // would otherwise blow both the batch limit and the function's memory.
            if (page.size < 400)
                break;
            last = page.docs[page.docs.length - 1];
        }
    }
}
async function loadThresholds() {
    const fallback = trustTier_1.DEFAULT_THRESHOLDS;
    try {
        const template = await (0, remote_config_1.getRemoteConfig)().getTemplate();
        const read = (key, dflt) => {
            const p = template.parameters[key]?.defaultValue;
            const v = p?.value;
            return v === undefined ? dflt : Number(v);
        };
        return {
            bronzeOrders: read("trust_bronze_min_orders", fallback.bronzeOrders),
            bronzeRating: read("trust_bronze_min_rating", fallback.bronzeRating),
            silverOrders: read("trust_silver_min_orders", fallback.silverOrders),
            silverRating: read("trust_silver_min_rating", fallback.silverRating),
            goldOrders: read("trust_gold_min_orders", fallback.goldOrders),
            goldRating: read("trust_gold_min_rating", fallback.goldRating),
            platinumOrders: read("trust_platinum_min_orders", fallback.platinumOrders),
            platinumRating: read("trust_platinum_min_rating", fallback.platinumRating),
            minFulfilmentRate: read("trust_min_fulfilment_rate", fallback.minFulfilmentRate),
            fulfilmentSampleFloor: read("trust_fulfilment_sample_floor", fallback.fulfilmentSampleFloor),
        };
    }
    catch {
        return fallback;
    }
}
//# sourceMappingURL=recomputeTrustTier.js.map