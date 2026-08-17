/**
 * The payment provider abstraction (§5.2).
 *
 * Everything gateway-specific lives behind this interface, so swapping
 * providers per market means writing one adapter — not touching order logic.
 *
 * The brief is explicit that the market matters here: cash on delivery still
 * leads most Iraqi online orders by trust, the dominant electronic rails are
 * telecom-backed wallets (ZainCash, AsiaHawala) and Qi Card, and Stripe does
 * not serve Iraq. Confirm current coverage before committing — this space
 * moves faster than documentation does.
 */
export interface PaymentProvider {
  readonly id: string;

  /** Creates a payment and returns whatever the client needs to complete it. */
  createPayment(input: CreatePaymentInput): Promise<CreatePaymentResult>;

  /**
   * Verifies a webhook came from the provider. Returns null if the signature
   * does not check out — an unverified webhook is an attacker telling us an
   * order was paid for.
   */
  verifyWebhook(rawBody: Buffer, headers: Record<string, string>): WebhookEvent | null;

  refund(paymentId: string, amountMinor: number): Promise<void>;
}

export interface CreatePaymentInput {
  orderId: string;
  amountMinor: number;
  currency: string;
  buyerPhone: string;
  /** Passed back to us on the webhook — this is how an event finds its order. */
  metadata: Record<string, string>;
}

export interface CreatePaymentResult {
  paymentId: string;
  /** Where to send the buyer, for redirect-based rails. */
  redirectUrl?: string;
  status: "pending" | "succeeded" | "failed";
}

export interface WebhookEvent {
  /** The provider's own event id — the key we deduplicate on. */
  eventId: string;
  orderId: string;
  paymentId: string;
  status: "succeeded" | "failed" | "refunded";
  amountMinor: number;
}

/**
 * Cash on delivery.
 *
 * Not a degraded fallback — it is the primary rail in this market, and
 * modelling it as a provider rather than an `if (cash)` branch keeps the order
 * flow identical whether money moves now or at the door.
 */
export class CashOnDeliveryProvider implements PaymentProvider {
  readonly id = "cash_on_delivery";

  async createPayment(
    input: CreatePaymentInput
  ): Promise<CreatePaymentResult> {
    // Nothing to charge yet. The order is confirmed immediately; the money
    // arrives with the courier.
    return {
      paymentId: `cod_${input.orderId}`,
      status: "succeeded",
    };
  }

  verifyWebhook(): WebhookEvent | null {
    return null; // there is no gateway to call back
  }

  async refund(): Promise<void> {
    // Nothing was taken. A cancelled COD order simply is not collected.
  }
}
