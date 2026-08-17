/**
 * Trust tier maths, extracted from the Firestore trigger.
 *
 * Pulled out as a pure function for one reason: it is the calculation that
 * decides what badge a stranger sees before deciding whether to send someone
 * money, and it was previously only reachable by firing a database trigger.
 * Pure input, pure output, directly testable.
 */
export interface Thresholds {
  bronzeOrders: number;
  bronzeRating: number;
  silverOrders: number;
  silverRating: number;
  goldOrders: number;
  goldRating: number;
  platinumOrders: number;
  platinumRating: number;

  /**
   * Minimum share of accepted orders a seller must actually fulfil.
   *
   * Accepting an order and then cancelling it is the most damaging thing a
   * seller can do short of fraud: the buyer has already chosen, paid attention,
   * and started waiting. Rating alone does not catch it, because the buyer of a
   * cancelled order usually never rates at all — so a seller who cancels half
   * their orders and delivers the rest well keeps a clean average.
   */
  minFulfilmentRate: number;

  /**
   * How many accepted orders before the rate is applied.
   *
   * Below this, one cancellation is noise rather than a pattern, and damning a
   * new seller for a single out-of-stock discovery would make the tier system
   * punish inexperience rather than unreliability.
   */
  fulfilmentSampleFloor: number;
}

/** Matches the illustrative table in §5.2. Overridden by Remote Config. */
export const DEFAULT_THRESHOLDS: Thresholds = {
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

export type Tier = "newSeller" | "bronze" | "silver" | "gold" | "platinum";

/**
 * BOTH conditions must hold, and the highest qualifying tier wins.
 *
 * A seller with 5,000 orders at 4.2 stars is Bronze, not Platinum. Volume alone
 * never buys a tier — that is the property that makes the badge mean something.
 */
export function tierFor(
  completedOrders: number,
  avgRating: number,
  t: Thresholds = DEFAULT_THRESHOLDS,
  sellerCancellations = 0
): Tier {
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
  const unreliable =
    accepted >= t.fulfilmentSampleFloor &&
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
export function aggregateRatings(ratings: number[]): {
  average: number;
  count: number;
  distribution: Record<string, number>;
} {
  const distribution: Record<string, number> = {
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
