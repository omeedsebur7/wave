/**
 * Promo code validation (§5.2).
 *
 * Pure, so the rules that decide whether someone gets money off are directly
 * testable rather than reachable only through a transaction. A discount bug is
 * a money bug in the same way a price bug is.
 */
export interface PromoCode {
  code: string;
  /** Exactly one of these is set. */
  percentOff?: number;
  amountOffMinor?: number;
  minimumOrderMinor?: number;
  /** Caps the absolute discount on a percentage code. */
  maxDiscountMinor?: number;
  expiresAtMs?: number;
  /** Total redemptions allowed across all users. */
  maxRedemptions?: number;
  redemptionCount?: number;
  /** Restrict to one seller's catalogue. */
  sellerId?: string;
  active?: boolean;
}

export type PromoRejection =
  | "not-found"
  | "inactive"
  | "expired"
  | "exhausted"
  | "already-used"
  | "below-minimum"
  | "wrong-seller";

export interface PromoResult {
  discountMinor: number;
  rejection?: PromoRejection;
}

export function applyPromo({
  promo,
  subtotalMinor,
  sellerId,
  alreadyUsedByBuyer,
  nowMs,
}: {
  promo: PromoCode | null;
  subtotalMinor: number;
  sellerId: string;
  alreadyUsedByBuyer: boolean;
  nowMs: number;
}): PromoResult {
  if (!promo) return { discountMinor: 0, rejection: "not-found" };
  if (promo.active === false) return { discountMinor: 0, rejection: "inactive" };

  if (promo.expiresAtMs !== undefined && promo.expiresAtMs <= nowMs) {
    return { discountMinor: 0, rejection: "expired" };
  }

  if (
    promo.maxRedemptions !== undefined &&
    (promo.redemptionCount ?? 0) >= promo.maxRedemptions
  ) {
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
  if (
    promo.minimumOrderMinor !== undefined &&
    subtotalMinor < promo.minimumOrderMinor
  ) {
    return { discountMinor: 0, rejection: "below-minimum" };
  }

  let discount = 0;
  if (promo.percentOff !== undefined) {
    discount = Math.floor((subtotalMinor * promo.percentOff) / 100);
    if (promo.maxDiscountMinor !== undefined) {
      discount = Math.min(discount, promo.maxDiscountMinor);
    }
  } else if (promo.amountOffMinor !== undefined) {
    discount = promo.amountOffMinor;
  }

  // Never below zero. A discount larger than the order must not turn into a
  // payment to the customer.
  discount = Math.max(0, Math.min(discount, subtotalMinor));

  return { discountMinor: discount };
}
