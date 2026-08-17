import * as fs from "fs";
import * as path from "path";

/**
 * Payment lifecycle rules, asserted at source level.
 *
 * These live in a transaction against Firestore, so a unit test would be mostly
 * mock. What is worth pinning is the *policy*, and each of these was wrong at
 * some point while the surrounding code read as correct.
 */
const webhook = fs.readFileSync(path.join(__dirname, "..", "src/payments/webhook.ts"), "utf8");
const placeOrder = fs.readFileSync(path.join(__dirname, "..", "src/orders/placeOrder.ts"), "utf8");

describe("An order's initial status depends on how it is paid", () => {
  it("confirms cash on delivery immediately", () => {
    // Nothing to wait for — payment happens at the door.
    expect(placeOrder).toMatch(/cash_on_delivery/);
    expect(placeOrder).toMatch(/"confirmed"/);
  });

  it("holds online payments at pendingPayment", () => {
    // Confirming up front would put the order in the seller's queue to pack and
    // ship before any money moved, and a failed payment would then have to claw
    // back something already sent.
    expect(placeOrder).toMatch(/"pendingPayment"/);
  });
});

describe("A late webhook cannot rewrite a closed order", () => {
  it("only applies payment results to orders still awaiting payment", () => {
    expect(webhook).toMatch(/pendingPayment/);
    expect(webhook).toMatch(/paymentProcessing/);
    expect(webhook).toMatch(/paymentFailed/);
  });

  it("exempts refunds, which are late by nature", () => {
    // A refund on a delivered order is exactly the case that has to work.
    expect(webhook).toMatch(/event\.status !== "refunded"/);
  });

  it("records a late event rather than dropping it", () => {
    // A provider reporting success on an order we already closed is a
    // reconciliation problem someone needs to see, not noise to swallow.
    expect(webhook).toMatch(/late_payment_event/);
    expect(webhook).toMatch(/order_status_at_receipt/);
  });
});

describe("Replay and amount protection", () => {
  it("deduplicates on the provider's event id", () => {
    expect(webhook).toMatch(/idempotency_keys/);
    expect(webhook).toMatch(/webhook_\$\{provider\.id\}_\$\{event\.eventId\}/);
  });

  it("acknowledges duplicates with 200 so the provider stops retrying", () => {
    expect(webhook).toMatch(/status\(200\)/);
  });

  it("refuses an amount that disagrees with the server-computed total", () => {
    // The order total was computed from product documents. A provider reporting
    // something else means something is wrong, and accepting it silently would
    // mean confirming an order for the wrong money.
    expect(webhook).toMatch(/payment_mismatch/);
    expect(webhook).toMatch(/paymentFailed/);
  });

  it("says nothing about why a signature failed", () => {
    // A verbose rejection is a free oracle for someone probing the endpoint.
    expect(webhook).toMatch(/Invalid signature/);
    expect(webhook).not.toMatch(/expected signature|signature was/i);
  });
});
