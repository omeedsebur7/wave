"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.applyPromo = applyPromo;
function applyPromo({ promo, subtotalMinor, sellerId, alreadyUsedByBuyer, nowMs, }) {
    if (!promo)
        return { discountMinor: 0, rejection: "not-found" };
    if (promo.active === false)
        return { discountMinor: 0, rejection: "inactive" };
    if (promo.expiresAtMs !== undefined && promo.expiresAtMs <= nowMs) {
        return { discountMinor: 0, rejection: "expired" };
    }
    if (promo.maxRedemptions !== undefined &&
        (promo.redemptionCount ?? 0) >= promo.maxRedemptions) {
        return { discountMinor: 0, rejection: "exhausted" };
    }
    // One redemption per buyer. Without this a single public code is a
    // permanent discount for anyone who remembers it.
    if (alreadyUsedByBuyer) {
        return { discountMinor: 0, rejection: "already-used" };
    }
    if (promo.sellerId !== undefined && promo.sellerId !== sellerId) {
        return { discountMinor: 0, rejection: "wrong-seller" };
    }
    // Checked against the SUBTOTAL, before any discount. Checking after would
    // let a code push an order below its own minimum and still apply.
    if (promo.minimumOrderMinor !== undefined &&
        subtotalMinor < promo.minimumOrderMinor) {
        return { discountMinor: 0, rejection: "below-minimum" };
    }
    let discount = 0;
    if (promo.percentOff !== undefined) {
        discount = Math.floor((subtotalMinor * promo.percentOff) / 100);
        if (promo.maxDiscountMinor !== undefined) {
            discount = Math.min(discount, promo.maxDiscountMinor);
        }
    }
    else if (promo.amountOffMinor !== undefined) {
        discount = promo.amountOffMinor;
    }
    // Never below zero. A discount larger than the order must not turn into a
    // payment to the customer.
    discount = Math.max(0, Math.min(discount, subtotalMinor));
    return { discountMinor: discount };
}
//# sourceMappingURL=promoCode.js.map