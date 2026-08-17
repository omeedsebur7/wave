import * as crypto from "crypto";
import type {
  CreatePaymentInput,
  CreatePaymentResult,
  PaymentProvider,
  WebhookEvent,
} from "./provider";

/**
 * ZainCash adapter.
 *
 * ZainCash uses JWT for both directions: we sign a request token with a shared
 * secret, and the callback arrives as a signed token we verify with the same
 * secret. That means the verification here is a signature check, not a string
 * comparison — and it is why `verifyWebhook` returns null rather than throwing
 * on a bad token, so the caller can respond 401 without leaking why.
 *
 * IMPORTANT: endpoints, field names and the exact token shape must be
 * confirmed against ZainCash's current merchant documentation before going
 * live. This adapter encodes the SHAPE of the integration correctly; the
 * specifics are the part that changes.
 */
export class ZainCashProvider implements PaymentProvider {
  readonly id = "zaincash";

  constructor(
    private readonly merchantId: string,
    private readonly secret: string,
    private readonly msisdn: string,
    private readonly baseUrl: string
  ) {}

  async createPayment(
    input: CreatePaymentInput
  ): Promise<CreatePaymentResult> {
    const now = Math.floor(Date.now() / 1000);

    const payload = {
      amount: input.amountMinor,
      serviceType: "WAVE order",
      msisdn: this.msisdn,
      // Our own order id, echoed back on the callback. Without it, a webhook
      // has no way to find the order it belongs to.
      orderId: input.orderId,
      redirectUrl: `https://wave.app/payment/return?order=${input.orderId}`,
      iat: now,
      exp: now + 60 * 60 * 4,
    };

    const token = this.signJwt(payload);

    const response = await fetch(`${this.baseUrl}/transaction/init`, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        token,
        merchantId: this.merchantId,
        lang: "en",
      }),
    });

    if (!response.ok) {
      throw new Error(`ZainCash init failed: ${response.status}`);
    }

    const data = (await response.json()) as { id?: string };
    if (!data.id) throw new Error("ZainCash returned no transaction id");

    return {
      paymentId: data.id,
      redirectUrl: `${this.baseUrl}/transaction/pay?id=${data.id}`,
      status: "pending",
    };
  }

  verifyWebhook(rawBody: Buffer): WebhookEvent | null {
    try {
      const params = new URLSearchParams(rawBody.toString());
      const token = params.get("token");
      if (!token) return null;

      const claims = this.verifyJwt(token);
      if (!claims) return null;

      const status = String(claims.status ?? "");

      return {
        // ZainCash's transaction id doubles as the event id — it is stable
        // across redeliveries, which is exactly what the dedupe ledger needs.
        eventId: String(claims.id ?? ""),
        orderId: String(claims.orderid ?? claims.orderId ?? ""),
        paymentId: String(claims.id ?? ""),
        status:
          status === "success"
            ? "succeeded"
            : status === "refunded"
              ? "refunded"
              : "failed",
        amountMinor: Number(claims.amount ?? 0),
      };
    } catch {
      // A malformed or unsigned callback is not an exception to log noisily —
      // it is an unauthenticated request, and the caller answers 401.
      return null;
    }
  }

  async refund(paymentId: string, amountMinor: number): Promise<void> {
    const now = Math.floor(Date.now() / 1000);
    const token = this.signJwt({
      id: paymentId,
      amount: amountMinor,
      msisdn: this.msisdn,
      iat: now,
      exp: now + 3600,
    });

    const response = await fetch(`${this.baseUrl}/transaction/refund`, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({ token, merchantId: this.merchantId }),
    });

    if (!response.ok) {
      throw new Error(`ZainCash refund failed: ${response.status}`);
    }
  }

  // ── Minimal HS256 JWT, to avoid a dependency for two functions ──────────

  private signJwt(payload: Record<string, unknown>): string {
    const header = this.b64({ alg: "HS256", typ: "JWT" });
    const body = this.b64(payload);
    const signature = crypto
      .createHmac("sha256", this.secret)
      .update(`${header}.${body}`)
      .digest("base64url");
    return `${header}.${body}.${signature}`;
  }

  private verifyJwt(token: string): Record<string, unknown> | null {
    const [header, body, signature] = token.split(".");
    if (!header || !body || !signature) return null;

    // Reject the alg:none downgrade explicitly. Without this, a token
    // declaring no algorithm is still checked against our HMAC — which happens
    // to fail today, but only by accident. Refusing anything that is not
    // HS256 makes it fail on purpose.
    try {
      const parsedHeader = JSON.parse(
        Buffer.from(header, "base64url").toString()
      ) as { alg?: string };
      if (parsedHeader.alg !== "HS256") return null;
    } catch {
      return null;
    }

    const expected = crypto
      .createHmac("sha256", this.secret)
      .update(`${header}.${body}`)
      .digest("base64url");

    // timingSafeEqual, not ===. String comparison leaks the signature one byte
    // at a time to anyone patient enough to measure the difference.
    const a = Buffer.from(signature);
    const b = Buffer.from(expected);
    if (a.length !== b.length || !crypto.timingSafeEqual(a, b)) return null;

    const claims = JSON.parse(
      Buffer.from(body, "base64url").toString()
    ) as Record<string, unknown>;

    // A valid signature on an expired token is still an expired token.
    const exp = Number(claims.exp ?? 0);
    if (exp > 0 && exp < Math.floor(Date.now() / 1000)) return null;

    return claims;
  }

  private b64(value: unknown): string {
    return Buffer.from(JSON.stringify(value)).toString("base64url");
  }
}
