"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.DEFAULT_THRESHOLDS = void 0;
exports.tierFor = tierFor;
exports.aggregateRatings = aggregateRatings;
/** Matches the illustrative table in §5.2. Overridden by Remote Config. */
exports.DEFAULT_THRESHOLDS = {
    bronzeOrders: 10,
    bronzeRating: 4.0,
    silverOrders: 50,
    silverRating: 4.3,
    goldOrders: 150,
    goldRating: 4.6,
    platinumOrders: 500,
    platinumRating: 4.8,
    minFulfilmentRate: 0.85,
    fulfilmentSampleFloor: 10,
};
/**
 * BOTH conditions must hold, and the highest qualifying tier wins.
 *
 * A seller with 5,000 orders at 4.2 stars is Bronze, not Platinum. Volume alone
 * never buys a tier — that is the property that makes the badge mean something.
 */
function tierFor(completedOrders, avgRating, t = exports.DEFAULT_THRESHOLDS, sellerCancellations = 0) {
    // Fulfilment gate, applied before any tier is awarded.
    //
    // The seller cancellation dialog tells people this affects their tier. It did
    // not, for a long time, which made the warning both false and toothless — the
    // behaviour it exists to discourage carried no consequence at all.
    //
    // Capped at Bronze rather than reset to newSeller: someone with 300 delivered
    // orders and a patchy stretch is not a stranger, and pretending otherwise
    // would erase real history a buyer should still be able to see.
    const accepted = completedOrders + sellerCancellations;
    const unreliable = accepted >= t.fulfilmentSampleFloor &&
        completedOrders / accepted < t.minFulfilmentRate;
    if (unreliable) {
        return completedOrders >= t.bronzeOrders && avgRating >= t.bronzeRating
            ? "bronze"
            : "newSeller";
    }
    if (completedOrders >= t.platinumOrders && avgRating >= t.platinumRating) {
        return "platinum";
    }
    if (completedOrders >= t.goldOrders && avgRating >= t.goldRating) {
        return "gold";
    }
    if (completedOrders >= t.silverOrders && avgRating >= t.silverRating) {
        return "silver";
    }
    if (completedOrders >= t.bronzeOrders && avgRating >= t.bronzeRating) {
        return "bronze";
    }
    return "newSeller";
}
/** Recomputed from scratch, never incrementally — see the trigger for why. */
function aggregateRatings(ratings) {
    const distribution = {
        "1": 0, "2": 0, "3": 0, "4": 0, "5": 0,
    };
    let sum = 0;
    let valid = 0;
    for (const raw of ratings) {
        const rating = Math.round(Number(raw));
        // Out-of-range values are dropped rather than clamped: a 7-star rating is
        // corrupt data, and clamping it to 5 would silently inflate the average.
        if (rating >= 1 && rating <= 5) {
            distribution[String(rating)] += 1;
            sum += rating;
            valid += 1;
        }
    }
    return {
        average: valid === 0 ? 0 : Number((sum / valid).toFixed(2)),
        count: valid,
        distribution,
    };
}
//# sourceMappingURL=trustTier.js.map