/**
 * Order total computation, extracted from placeOrder.
 *
 * This runs server-side and takes prices from the product documents, never
 * from the request. A client that sends its own total is a client that can buy
 * a $500 item for $5 — so the arithmetic that decides what someone is charged
 * is worth having under direct test rather than only reachable through a
 * callable and a transaction.
 */
export interface LineInput {
  productId: string;
  quantity: number;
}

export interface ProductSnapshot {
  productId: string;
  title: string;
  sellerId: string;
  priceMinor: number;
  currency: string;
  stock: number;
  imageUrl?: string;
}

export interface ComputedOrder {
  totalMinor: number;
  currency: string;
  sellerId: string;
  productIds: string[];
  items: Array<{
    product_id: string;
    title: string;
    unit_price_minor: number;
    quantity: number;
    image_url: string;
  }>;
}

/**
 * Ceiling on a single order, in minor units.
 *
 * One billion IQD is roughly USD 750,000 — far above any plausible marketplace
 * order and far below the point where JavaScript integers lose precision. The
 * gap between those two bounds is where a typo or a corrupted price document
 * lands, and refusing there costs a legitimate seller nothing.
 */
export const MAX_ORDER_MINOR = 1_000_000_000;

export class OrderComputationError extends Error {
  constructor(
    readonly code:
  | "not-found"
  | "out-of-range"
  | "invalid-argument"
  | "failed-precondition",
    message: string
  ) {
    super(message);
  }
}

export function computeOrder(
  lines: LineInput[],
  products: Map<string, ProductSnapshot>,
  /**
   * Who is buying. Optional so the pure-arithmetic tests need not supply one,
   * but `placeOrder` always passes it — see the self-purchase check below.
   */
  buyerId?: string
): ComputedOrder {
  if (lines.length === 0) {
    throw new OrderComputationError("invalid-argument", "Cart is empty");
  }

  let totalMinor = 0;
  let currency = "IQD";
  let firstCurrency: string | null = null;
  let sellerId: string | null = null;
  const productIds: string[] = [];
  const items: ComputedOrder["items"] = [];

  for (const line of lines) {
    const product = products.get(line.productId);
    if (!product) {
      throw new OrderComputationError(
        "not-found",
        `Product ${line.productId} not found`
      );
    }

    const quantity = Math.floor(Number(line.quantity));
    if (!Number.isFinite(quantity) || quantity < 1) {
      throw new OrderComputationError(
        "invalid-argument",
        "Quantity must be a positive whole number"
      );
    }
    if (quantity > product.stock) {
      throw new OrderComputationError(
        "out-of-range",
        `${product.title} is out of stock`
      );
    }

    // v1 keeps an order to a single seller — split-seller carts need split
    // payouts and split fulfilment, which is Phase 2 territory.
    if (sellerId !== null && sellerId !== product.sellerId) {
      throw new OrderComputationError(
        "invalid-argument",
        "Items from different sellers must be ordered separately"
      );
    }
    // Nobody buys from themselves.
    //
    // This is the self-dealing attack on any marketplace with a reputation
    // system, and here it is free: with cash on delivery no money moves at all,
    // so a seller could place an order with themselves, mark it delivered, and
    // rate themselves five stars. Repeat a hundred times and you have Gold.
    //
    // Every downstream check assumes the buyer and seller are different people
    // — the review rule verifies the author was the buyer, the rating rule the
    // same — so blocking it here is what makes all of those mean something.
    if (buyerId !== undefined && buyerId === product.sellerId) {
      throw new OrderComputationError(
        "failed-precondition",
        "You cannot buy your own listing"
      );
    }

    sellerId = product.sellerId;

    // Currency is CHECKED, not overwritten.
    //
    // The previous version assigned it on every line, so a cart mixing two
    // currencies took whichever product came last and summed the amounts as if
    // they were the same unit — 25,000 IQD plus 20 USD becoming "25,020" of
    // something. Nothing prevents a seller listing in both, and the failure is
    // silent and financial, which is the worst combination.
    if (firstCurrency !== null && firstCurrency !== product.currency) {
      throw new OrderComputationError(
        "invalid-argument",
        "Items priced in different currencies must be ordered separately"
      );
    }
    firstCurrency = product.currency;
    currency = product.currency;

    // Prices come from the product document, which only a seller can write, so
    // this is not defence against a hostile client — it is defence against a
    // typo. A seller who means 25,000 and types 25,000,000,000 should have the
    // order refused rather than a buyer charged, and a corrupted document
    // should not silently produce an order nobody can honour.
    if (!Number.isSafeInteger(product.priceMinor) || product.priceMinor < 0) {
      throw new OrderComputationError(
        "failed-precondition",
        `${product.title} has an invalid price`
      );
    }

    const lineTotal = product.priceMinor * quantity;
    if (!Number.isSafeInteger(lineTotal) || lineTotal > MAX_ORDER_MINOR) {
      throw new OrderComputationError(
        "out-of-range",
        "That order total is too large. Split it into smaller orders."
      );
    }

    totalMinor += lineTotal;
    productIds.push(product.productId);
    items.push({
      product_id: product.productId,
      title: product.title,
      unit_price_minor: product.priceMinor,
      quantity,
      image_url: product.imageUrl ?? "",
    });
  }

  if (totalMinor > MAX_ORDER_MINOR) {
    throw new OrderComputationError(
      "out-of-range",
      "That order total is too large. Split it into smaller orders."
    );
  }

  return {
    totalMinor,
    currency,
    sellerId: sellerId!,
    productIds,
    items,
  };
}
