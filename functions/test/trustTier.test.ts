import {
  aggregateRatings,
  DEFAULT_THRESHOLDS,
  tierFor,
} from "../src/domain/trustTier";

describe("Tier assignment", () => {
  it("gives a new seller no tier", () => {
    expect(tierFor(0, 0)).toBe("newSeller");
    expect(tierFor(9, 5.0)).toBe("newSeller");
  });

  it("treats the threshold as inclusive", () => {
    expect(tierFor(10, 4.0)).toBe("bronze");
    expect(tierFor(9, 4.0)).toBe("newSeller");
    expect(tierFor(10, 3.99)).toBe("newSeller");
  });

  it("does NOT let volume alone buy a tier", () => {
    // The property that makes the badge mean anything. 5,000 orders at 4.2
    // stars is Bronze, not Platinum.
    expect(tierFor(5000, 4.2)).toBe("bronze");
    expect(tierFor(5000, 4.5)).toBe("silver");
    expect(tierFor(5000, 4.7)).toBe("gold");
    expect(tierFor(5000, 4.9)).toBe("platinum");
  });

  it("does not let a perfect rating alone buy a tier either", () => {
    expect(tierFor(12, 5.0)).toBe("bronze");
    expect(tierFor(60, 5.0)).toBe("silver");
  });

  it("awards the highest qualifying tier", () => {
    expect(tierFor(600, 4.9)).toBe("platinum");
    expect(tierFor(600, 4.65)).toBe("gold");
  });

  it("respects overridden thresholds from Remote Config", () => {
    // The brief is explicit these are tunable, not hardcoded.
    const strict = { ...DEFAULT_THRESHOLDS, bronzeOrders: 100 };
    expect(tierFor(50, 5.0, strict)).toBe("newSeller");
  });
});

describe("Rating aggregation", () => {
  it("averages to two decimal places", () => {
    expect(aggregateRatings([5, 4, 4]).average).toBe(4.33);
  });

  it("returns zero rather than NaN for an empty set", () => {
    // A NaN average would render as "NaN stars" on a profile.
    const result = aggregateRatings([]);
    expect(result.average).toBe(0);
    expect(result.count).toBe(0);
  });

  it("builds a full 1-5 distribution, including empty buckets", () => {
    // The UI draws a bar per star; a missing key would render nothing rather
    // than an empty bar, which reads as a rendering bug.
    const result = aggregateRatings([5, 5, 3]);
    expect(result.distribution).toEqual({
      "1": 0, "2": 0, "3": 1, "4": 0, "5": 2,
    });
  });

  it("drops corrupt ratings instead of clamping them", () => {
    // Clamping a 7 to a 5 would silently inflate the average. Dropping it is
    // the honest treatment of data that should not exist.
    const result = aggregateRatings([5, 7, 0, -3, 4]);
    expect(result.count).toBe(2);
    expect(result.average).toBe(4.5);
  });

  it("distinguishes two sets that share an average", () => {
    // This is the whole reason the distribution is stored alongside the mean:
    // all-4s and half-5s/half-3s are very different products.
    const allFours = aggregateRatings([4, 4, 4, 4]);
    const split = aggregateRatings([5, 5, 3, 3]);
    expect(allFours.average).toBe(split.average);
    expect(allFours.distribution).not.toEqual(split.distribution);
  });
});

describe("Fulfilment gate", () => {
  // The seller cancellation dialog tells people this affects their tier. It did
  // not, for a long time, which made the warning both false and toothless.
  //
  // Rating alone cannot catch it: the buyer of a cancelled order usually never
  // rates at all, so a seller who cancels half their orders and delivers the
  // rest well keeps a spotless average.

  it("lets a reliable seller reach the tier their numbers earn", () => {
    expect(tierFor(200, 4.7, DEFAULT_THRESHOLDS, 5)).toBe("gold");
  });

  it("caps an unreliable seller at Bronze however good their rating", () => {
    // 100 delivered, 100 cancelled — a 50% fulfilment rate with a perfect 4.9
    // from the half who received anything.
    expect(tierFor(100, 4.9, DEFAULT_THRESHOLDS, 100)).toBe("bronze");
  });

  it("does not damn a new seller for one cancellation", () => {
    // Below the sample floor, one out-of-stock discovery is noise, not a
    // pattern. Punishing it would make the tier measure inexperience.
    expect(tierFor(4, 5.0, DEFAULT_THRESHOLDS, 1)).toBe("newSeller");
    expect(tierFor(12, 4.5, DEFAULT_THRESHOLDS, 1)).toBe("bronze");
  });

  it("applies the gate once there is enough history to judge", () => {
    // 6 delivered, 6 cancelled: 12 accepted clears the floor, 50% fails.
    expect(tierFor(6, 5.0, DEFAULT_THRESHOLDS, 6)).toBe("newSeller");
  });

  it("keeps Bronze for someone with real history and a bad patch", () => {
    // 300 delivered is not a stranger. Resetting them to newSeller would erase
    // history a buyer should still be able to see.
    expect(tierFor(300, 4.6, DEFAULT_THRESHOLDS, 300)).toBe("bronze");
  });

  it("passes a seller sitting exactly on the threshold", () => {
    // 85 of 100 accepted is exactly 0.85, which is allowed rather than refused.
    // An inclusive boundary matters when the number is a published rule.
    expect(tierFor(85, 4.7, DEFAULT_THRESHOLDS, 15)).toBe("silver");
  });

  it("fails a seller a single order below it", () => {
    expect(tierFor(84, 4.7, DEFAULT_THRESHOLDS, 16)).toBe("bronze");
  });

  it("ignores cancellations entirely when there are none", () => {
    // The default argument must not change any existing behaviour.
    expect(tierFor(200, 4.7)).toBe(tierFor(200, 4.7, DEFAULT_THRESHOLDS, 0));
  });

  it("treats a seller with no orders at all as new, not unreliable", () => {
    // 0/0 is not a failure rate. Dividing without the sample floor would make
    // every brand-new account look like it had never fulfilled anything.
    expect(tierFor(0, 0, DEFAULT_THRESHOLDS, 0)).toBe("newSeller");
  });
});
