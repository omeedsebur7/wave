import { applyPromo, PromoCode } from "../src/domain/promoCode";

const NOW = Date.UTC(2026, 7, 5);

const promo = (over: Partial<PromoCode> = {}): PromoCode => ({
  code: "SAVE10",
  percentOff: 10,
  active: true,
  ...over,
});

const run = (p: PromoCode | null, over: Partial<{
  subtotalMinor: number; sellerId: string; alreadyUsedByBuyer: boolean;
}> = {}) =>
  applyPromo({
    promo: p,
    subtotalMinor: 100000,
    sellerId: "seller_1",
    alreadyUsedByBuyer: false,
    nowMs: NOW,
    ...over,
  });

describe("Discount arithmetic", () => {
  it("applies a percentage", () => {
    expect(run(promo({ percentOff: 10 })).discountMinor).toBe(10000);
  });

  it("applies a fixed amount", () => {
    expect(
      run(promo({ percentOff: undefined, amountOffMinor: 5000 })).discountMinor
    ).toBe(5000);
  });

  it("caps a percentage at maxDiscountMinor", () => {
    // Without the cap, a 50%-off code on an expensive order is an unbounded
    // liability.
    expect(
      run(promo({ percentOff: 50, maxDiscountMinor: 20000 })).discountMinor
    ).toBe(20000);
  });

  it("never discounts more than the order is worth", () => {
    // A discount exceeding the subtotal must not become a payment TO the
    // customer.
    const result = run(
      promo({ percentOff: undefined, amountOffMinor: 999999 }),
      { subtotalMinor: 25000 }
    );
    expect(result.discountMinor).toBe(25000);
  });

  it("never returns a negative discount", () => {
    const result = run(promo({ percentOff: -50 }));
    expect(result.discountMinor).toBeGreaterThanOrEqual(0);
  });

  it("floors rather than rounds, so the seller never loses a unit", () => {
    expect(run(promo({ percentOff: 33 }), { subtotalMinor: 1000 })
      .discountMinor).toBe(330);
  });
});

describe("Rejections", () => {
  it("rejects an unknown code", () => {
    expect(run(null).rejection).toBe("not-found");
  });

  it("rejects a deactivated code", () => {
    expect(run(promo({ active: false })).rejection).toBe("inactive");
  });

  it("rejects an expired code", () => {
    expect(run(promo({ expiresAtMs: NOW - 1 })).rejection).toBe("expired");
  });

  it("accepts a code expiring in the future", () => {
    expect(run(promo({ expiresAtMs: NOW + 1000 })).rejection).toBeUndefined();
  });

  it("rejects a code past its global redemption limit", () => {
    expect(
      run(promo({ maxRedemptions: 100, redemptionCount: 100 })).rejection
    ).toBe("exhausted");
  });

  it("rejects a second use by the same buyer", () => {
    // Without this, one public code is a permanent discount for anyone who
    // remembers it.
    expect(run(promo(), { alreadyUsedByBuyer: true }).rejection)
      .toBe("already-used");
  });

  it("rejects a seller-scoped code used elsewhere", () => {
    expect(
      run(promo({ sellerId: "seller_2" })).rejection
    ).toBe("wrong-seller");
  });

  it("checks the minimum against the subtotal, before the discount", () => {
    // Checking after would let a code push an order below its own minimum and
    // still apply — the order would qualify only because the code was applied.
    expect(
      run(promo({ minimumOrderMinor: 200000 })).rejection
    ).toBe("below-minimum");
    expect(
      run(promo({ minimumOrderMinor: 100000 })).rejection
    ).toBeUndefined();
  });

  it("returns zero discount alongside every rejection", () => {
    // A caller that ignored the rejection must not accidentally apply a
    // discount anyway.
    for (const p of [
      null,
      promo({ active: false }),
      promo({ expiresAtMs: NOW - 1 }),
      promo({ maxRedemptions: 1, redemptionCount: 1 }),
      promo({ sellerId: "other" }),
      promo({ minimumOrderMinor: 999999 }),
    ]) {
      expect(run(p).discountMinor).toBe(0);
    }
  });
});
