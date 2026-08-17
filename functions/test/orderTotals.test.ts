import {
  computeOrder,
  OrderComputationError,
  ProductSnapshot,
} from "../src/domain/orderTotals";

const product = (over: Partial<ProductSnapshot> = {}): ProductSnapshot => ({
  productId: "p1",
  title: "Thing",
  sellerId: "seller_1",
  priceMinor: 25000,
  currency: "IQD",
  stock: 10,
  ...over,
});

const catalogue = (...items: ProductSnapshot[]) =>
  new Map(items.map((p) => [p.productId, p]));

describe("Order totals are computed from the catalogue, never the request", () => {
  it("multiplies the SERVER price by quantity", () => {
    const result = computeOrder(
      [{ productId: "p1", quantity: 3 }],
      catalogue(product({ priceMinor: 25000 }))
    );
    expect(result.totalMinor).toBe(75000);
  });

  it("sums multiple lines from the same seller", () => {
    const result = computeOrder(
      [
        { productId: "p1", quantity: 2 },
        { productId: "p2", quantity: 1 },
      ],
      catalogue(
        product({ productId: "p1", priceMinor: 10000 }),
        product({ productId: "p2", priceMinor: 5000 })
      )
    );
    expect(result.totalMinor).toBe(25000);
    expect(result.productIds).toEqual(["p1", "p2"]);
  });

  it("emits product_ids as a flat array for the review rules", () => {
    // The reviews rule checks membership of this array to enforce "you can
    // only review what you actually bought". If the shape changes, that rule
    // silently stops working.
    const result = computeOrder(
      [{ productId: "p1", quantity: 1 }],
      catalogue(product())
    );
    expect(Array.isArray(result.productIds)).toBe(true);
    expect(result.productIds).toContain("p1");
  });
});

describe("Stock", () => {
  it("rejects a quantity above available stock", () => {
    expect(() =>
      computeOrder(
        [{ productId: "p1", quantity: 11 }],
        catalogue(product({ stock: 10 }))
      )
    ).toThrow(OrderComputationError);
  });

  it("allows buying the exact remaining stock", () => {
    const result = computeOrder(
      [{ productId: "p1", quantity: 10 }],
      catalogue(product({ stock: 10 }))
    );
    expect(result.items[0].quantity).toBe(10);
  });

  it("rejects an order for something out of stock", () => {
    expect(() =>
      computeOrder(
        [{ productId: "p1", quantity: 1 }],
        catalogue(product({ stock: 0 }))
      )
    ).toThrow(/out of stock/);
  });
});

describe("Quantities that would be exploitable", () => {
  it("rejects a negative quantity", () => {
    // Without this, a negative line subtracts from the total — a cart that
    // pays the customer.
    expect(() =>
      computeOrder(
        [{ productId: "p1", quantity: -5 }],
        catalogue(product())
      )
    ).toThrow(OrderComputationError);
  });

  it("rejects zero", () => {
    expect(() =>
      computeOrder([{ productId: "p1", quantity: 0 }], catalogue(product()))
    ).toThrow(OrderComputationError);
  });

  it("rejects a fractional quantity rather than rounding it", () => {
    expect(() =>
      computeOrder(
        [{ productId: "p1", quantity: 0.5 }],
        catalogue(product())
      )
    ).toThrow(OrderComputationError);
  });

  it("rejects NaN and Infinity", () => {
    for (const bad of [NaN, Infinity, -Infinity]) {
      expect(() =>
        computeOrder(
          [{ productId: "p1", quantity: bad }],
          catalogue(product())
        )
      ).toThrow(OrderComputationError);
    }
  });

  it("rejects an unknown product rather than treating it as free", () => {
    expect(() =>
      computeOrder([{ productId: "ghost", quantity: 1 }], catalogue(product()))
    ).toThrow(/not found/);
  });

  it("rejects an empty cart", () => {
    expect(() => computeOrder([], catalogue(product()))).toThrow(
      /Cart is empty/
    );
  });
});

describe("Single-seller constraint (v1)", () => {
  it("rejects a cart spanning two sellers", () => {
    expect(() =>
      computeOrder(
        [
          { productId: "p1", quantity: 1 },
          { productId: "p2", quantity: 1 },
        ],
        catalogue(
          product({ productId: "p1", sellerId: "seller_1" }),
          product({ productId: "p2", sellerId: "seller_2" })
        )
      )
    ).toThrow(/different sellers/);
  });

  it("carries the seller through to the order", () => {
    const result = computeOrder(
      [{ productId: "p1", quantity: 1 }],
      catalogue(product({ sellerId: "seller_9" }))
    );
    expect(result.sellerId).toBe("seller_9");
  });
});

describe("Currency is validated, not overwritten", () => {
  // The previous version assigned `currency` on every line, so a mixed cart
  // took whichever product came last and summed the amounts as though they were
  // the same unit. Silent and financial — the worst pair.
  const iqd: ProductSnapshot = {
    productId: "p_iqd",
    sellerId: "s1",
    title: "Priced in dinars",
    priceMinor: 25000,
    currency: "IQD",
    stock: 10,
  };
  const usd: ProductSnapshot = {
    productId: "p_usd",
    sellerId: "s1",
    title: "Priced in dollars",
    priceMinor: 2000,
    currency: "USD",
    stock: 10,
  };

  it("refuses a cart mixing two currencies", () => {
    expect(() =>
      computeOrder({
        lines: [
          { productId: "p_iqd", quantity: 1 },
          { productId: "p_usd", quantity: 1 },
        ],
        products: new Map([
          ["p_iqd", iqd],
          ["p_usd", usd],
        ]),
      })
    ).toThrow(/different currencies/);
  });

  it("accepts a cart in one currency and reports it", () => {
    const result = computeOrder({
      lines: [{ productId: "p_usd", quantity: 2 }],
      products: new Map([["p_usd", usd]]),
    });
    expect(result.currency).toBe("USD");
    expect(result.totalMinor).toBe(4000);
  });

  it("does not let ordering hide the mismatch", () => {
    // Same cart, reversed. A check that only compared against the running value
    // would pass in one direction and fail in the other.
    expect(() =>
      computeOrder({
        lines: [
          { productId: "p_usd", quantity: 1 },
          { productId: "p_iqd", quantity: 1 },
        ],
        products: new Map([
          ["p_usd", usd],
          ["p_iqd", iqd],
        ]),
      })
    ).toThrow(/different currencies/);
  });
});

describe("Order totals are bounded", () => {
  // Not defence against a hostile client — prices come from a document only the
  // seller can write. Defence against a typo, and against a corrupted document
  // silently producing an order nobody can honour.
  const absurd: ProductSnapshot = {
    productId: "p_big",
    sellerId: "s1",
    title: "Fat-fingered price",
    priceMinor: 25_000_000_000,
    currency: "IQD",
    stock: 5,
  };

  it("refuses a single line above the ceiling", () => {
    expect(() =>
      computeOrder({
        lines: [{ productId: "p_big", quantity: 1 }],
        products: new Map([["p_big", absurd]]),
      })
    ).toThrow(/too large/);
  });

  it("refuses a total that only exceeds the ceiling once summed", () => {
    // Each line is fine; the order is not. Checking only per-line would miss it.
    const chunky: ProductSnapshot = {
      ...absurd,
      priceMinor: 400_000_000,
      stock: 10,
    };
    expect(() =>
      computeOrder({
        lines: [{ productId: "p_big", quantity: 3 }],
        products: new Map([["p_big", chunky]]),
      })
    ).toThrow(/too large/);
  });

  it("refuses a negative price rather than crediting the buyer", () => {
    expect(() =>
      computeOrder({
        lines: [{ productId: "p_neg", quantity: 1 }],
        products: new Map([
          ["p_neg", { ...absurd, productId: "p_neg", priceMinor: -5000 }],
        ]),
      })
    ).toThrow(/invalid price/);
  });

  it("still accepts an ordinary order comfortably below the ceiling", () => {
    const result = computeOrder({
      lines: [{ productId: "p_ok", quantity: 3 }],
      products: new Map([
        ["p_ok", { ...absurd, productId: "p_ok", priceMinor: 25000 }],
      ]),
    });
    expect(result.totalMinor).toBe(75000);
  });
});

describe("Nobody buys from themselves", () => {
  // The self-dealing attack on any marketplace with a reputation system, and
  // here it is free: with cash on delivery no money moves at all. A seller could
  // order from themselves, mark it delivered, rate themselves five stars, and
  // repeat until Gold.
  //
  // Every downstream check assumes buyer and seller are different people — the
  // review rule verifies the author was the buyer, the rating rule the same — so
  // this is what makes all of those mean anything.
  const own: ProductSnapshot = {
    productId: "p_own",
    sellerId: "seller_1",
    title: "My own listing",
    priceMinor: 25000,
    currency: "IQD",
    stock: 10,
  };

  it("refuses an order where the buyer is the seller", () => {
    expect(() =>
      computeOrder(
        [{ productId: "p_own", quantity: 1 }],
        new Map([["p_own", own]]),
        "seller_1"
      )
    ).toThrow(/your own listing/);
  });

  it("allows anyone else to buy the same product", () => {
    const result = computeOrder(
      [{ productId: "p_own", quantity: 1 }],
      new Map([["p_own", own]]),
      "someone_else"
    );
    expect(result.totalMinor).toBe(25000);
  });

  it("refuses even when the self-bought item is one line of several", () => {
    // Hiding it among legitimate items must not get it through.
    const other: ProductSnapshot = {
      ...own,
      productId: "p_other",
      sellerId: "seller_1",
      title: "Also mine",
    };
    expect(() =>
      computeOrder(
        [
          { productId: "p_other", quantity: 1 },
          { productId: "p_own", quantity: 1 },
        ],
        new Map([
          ["p_other", other],
          ["p_own", own],
        ]),
        "seller_1"
      )
    ).toThrow(/your own listing/);
  });

  it("still computes normally when no buyer is supplied", () => {
    // The pure-arithmetic tests pass no buyer; the parameter must not change
    // their behaviour.
    const result = computeOrder(
      [{ productId: "p_own", quantity: 2 }],
      new Map([["p_own", own]])
    );
    expect(result.totalMinor).toBe(50000);
  });
});
