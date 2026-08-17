import * as crypto from "crypto";
import { ZainCashProvider } from "../src/payments/providers/zaincash";
import { CashOnDeliveryProvider } from "../src/payments/providers/provider";

const SECRET = "test-secret-key";
const provider = new ZainCashProvider(
  "merchant_1",
  SECRET,
  "9647700000000",
  "https://test.zaincash.invalid"
);

/** Builds a signed callback token the way ZainCash would. */
function signToken(
  claims: Record<string, unknown>,
  secret = SECRET
): string {
  const b64 = (v: unknown) =>
    Buffer.from(JSON.stringify(v)).toString("base64url");
  const header = b64({ alg: "HS256", typ: "JWT" });
  const body = b64(claims);
  const signature = crypto
    .createHmac("sha256", secret)
    .update(`${header}.${body}`)
    .digest("base64url");
  return `${header}.${body}.${signature}`;
}

const validClaims = (over: Record<string, unknown> = {}) => ({
  id: "txn_123",
  orderid: "order_abc",
  status: "success",
  amount: 25000,
  exp: Math.floor(Date.now() / 1000) + 3600,
  ...over,
});

const callback = (token: string) =>
  Buffer.from(new URLSearchParams({ token }).toString());

describe("Webhook signature verification", () => {
  it("accepts a correctly signed callback", () => {
    const event = provider.verifyWebhook(callback(signToken(validClaims())));

    expect(event).not.toBeNull();
    expect(event!.orderId).toBe("order_abc");
    expect(event!.paymentId).toBe("txn_123");
    expect(event!.status).toBe("succeeded");
    expect(event!.amountMinor).toBe(25000);
  });

  it("rejects a token signed with the wrong secret", () => {
    // An attacker telling us an order was paid for.
    const forged = signToken(validClaims(), "attacker-secret");
    expect(provider.verifyWebhook(callback(forged))).toBeNull();
  });

  it("rejects a token whose payload was edited after signing", () => {
    const token = signToken(validClaims({ amount: 100 }));
    const [header, , signature] = token.split(".");
    const tamperedBody = Buffer.from(
      JSON.stringify(validClaims({ amount: 9999999 }))
    ).toString("base64url");

    expect(
      provider.verifyWebhook(
        callback(`${header}.${tamperedBody}.${signature}`)
      )
    ).toBeNull();
  });

  it("rejects an expired token even though its signature is valid", () => {
    // A replayed callback from last month is still a replayed callback.
    const expired = signToken(
      validClaims({ exp: Math.floor(Date.now() / 1000) - 60 })
    );
    expect(provider.verifyWebhook(callback(expired))).toBeNull();
  });

  it("rejects a signature of the wrong length without throwing", () => {
    // timingSafeEqual throws on mismatched lengths, so the length check has to
    // come first — otherwise a truncated signature crashes the function
    // instead of returning 401.
    const [header, body] = signToken(validClaims()).split(".");
    expect(() =>
      provider.verifyWebhook(callback(`${header}.${body}.short`))
    ).not.toThrow();
    expect(provider.verifyWebhook(callback(`${header}.${body}.short`))).toBeNull();
  });

  it("rejects a malformed token rather than throwing", () => {
    for (const bad of ["", "not-a-jwt", "a.b", "...", "a..c"]) {
      expect(() => provider.verifyWebhook(callback(bad))).not.toThrow();
      expect(provider.verifyWebhook(callback(bad))).toBeNull();
    }
  });

  it("rejects a callback with no token at all", () => {
    expect(provider.verifyWebhook(Buffer.from("status=success"))).toBeNull();
  });

  it("rejects the alg:none downgrade", () => {
    // The classic JWT attack: strip the signature and claim no algorithm.
    const b64 = (v: unknown) =>
      Buffer.from(JSON.stringify(v)).toString("base64url");
    const unsigned = `${b64({ alg: "none", typ: "JWT" })}.${b64(validClaims())}.`;
    expect(provider.verifyWebhook(callback(unsigned))).toBeNull();
  });
});

describe("Status mapping", () => {
  it("maps success to succeeded", () => {
    const event = provider.verifyWebhook(
      callback(signToken(validClaims({ status: "success" })))
    );
    expect(event!.status).toBe("succeeded");
  });

  it("maps refunded through", () => {
    const event = provider.verifyWebhook(
      callback(signToken(validClaims({ status: "refunded" })))
    );
    expect(event!.status).toBe("refunded");
  });

  it("treats anything unrecognised as failed, not succeeded", () => {
    // Defaulting an unknown status to success would let an unexpected provider
    // state mark an order paid.
    for (const status of ["pending", "cancelled", "weird", ""]) {
      const event = provider.verifyWebhook(
        callback(signToken(validClaims({ status })))
      );
      expect(event!.status).toBe("failed");
    }
  });

  it("accepts either orderid spelling the provider might send", () => {
    const snake = provider.verifyWebhook(
      callback(signToken({ ...validClaims(), orderid: "order_x" }))
    );
    expect(snake!.orderId).toBe("order_x");

    const camel = provider.verifyWebhook(
      callback(
        signToken({
          id: "t",
          orderId: "order_y",
          status: "success",
          amount: 1,
          exp: Math.floor(Date.now() / 1000) + 60,
        })
      )
    );
    expect(camel!.orderId).toBe("order_y");
  });
});

describe("Cash on delivery", () => {
  const cod = new CashOnDeliveryProvider();

  it("confirms immediately — there is nothing to charge yet", async () => {
    const result = await cod.createPayment({
      orderId: "order_1",
      amountMinor: 25000,
      currency: "IQD",
      buyerPhone: "+9647700000000",
      metadata: {},
    });
    expect(result.status).toBe("succeeded");
    expect(result.redirectUrl).toBeUndefined();
  });

  it("has no webhook, because there is no gateway to call back", () => {
    expect(cod.verifyWebhook()).toBeNull();
  });

  it("refunds are a no-op — nothing was taken", async () => {
    await expect(cod.refund()).resolves.toBeUndefined();
  });

  it("shares the interface with ZainCash so the order flow does not branch",
    () => {
      // Modelling cash as a provider rather than an `if (cash)` branch is the
      // point: the order flow is identical whether money moves now or at the
      // door.
      for (const method of ["createPayment", "verifyWebhook", "refund"]) {
        expect(typeof (cod as any)[method]).toBe("function");
        expect(typeof (provider as any)[method]).toBe("function");
      }
    });
});
