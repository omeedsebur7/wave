"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.paymentWebhook = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const params_1 = require("firebase-functions/params");
const zaincash_1 = require("./providers/zaincash");
const ZAINCASH_SECRET = (0, params_1.defineSecret)("ZAINCASH_SECRET");
const ZAINCASH_MERCHANT_ID = (0, params_1.defineSecret)("ZAINCASH_MERCHANT_ID");
const ZAINCASH_MSISDN = (0, params_1.defineSecret)("ZAINCASH_MSISDN");
const ZAINCASH_BASE_URL = (0, params_1.defineSecret)("ZAINCASH_BASE_URL");
/**
 * Resolves the adapter for an incoming webhook.
 *
 * Keyed by URL path rather than by sniffing the payload: each provider gets
 * its own callback URL, so there is never a question of which adapter should
 * parse a request, and adding a second market means adding a case here.
 */
function providerFor(path) {
    if (path.includes("zaincash")) {
        return new zaincash_1.ZainCashProvider(ZAINCASH_MERCHANT_ID.value(), ZAINCASH_SECRET.value(), ZAINCASH_MSISDN.value(), ZAINCASH_BASE_URL.value());
    }
    return null;
}
/**
 * Payment provider webhook.
 *
 * Payment gateways retry aggressively and deliver AT LEAST ONCE â€” a redelivery
 * is normal operation, not an error. So the handler dedupes on the provider's
 * event id before touching the order.
 *
 * The provider abstraction (Â§5.2) means this file is the only place that knows
 * a specific gateway's payload shape. Swapping providers per market â€” ZainCash,
 * AsiaHawala, Qi Card, PayTabs â€” means writing a new normaliser, not touching
 * order logic.
 */
exports.paymentWebhook = (0, https_1.onRequest)({
    secrets: [
        ZAINCASH_SECRET,
        ZAINCASH_MERCHANT_ID,
        ZAINCASH_MSISDN,
        ZAINCASH_BASE_URL,
    ],
}, async (req, res) => {
    const provider = providerFor(req.path);
    if (!provider) {
        res.status(404).send("Unknown provider");
        return;
    }
    // The adapter owns signature verification, because each provider signs
    // differently â€” ZainCash uses a signed JWT, others use an HMAC header.
    // A null result means unauthenticated, and we say nothing about why.
    const event = provider.verifyWebhook(req.rawBody, req.headers);
    if (!event) {
        res.status(401).send("Invalid signature");
        return;
    }
    if (!event.eventId || !event.orderId) {
        res.status(400).send("Malformed payload");
        return;
    }
    const db = (0, firestore_1.getFirestore)();
    const eventRef = db
        .collection("idempotency_keys")
        .doc(`webhook_${provider.id}_${event.eventId}`);
    await db.runTransaction(async (tx) => {
        const seen = await tx.get(eventRef);
        if (seen.exists)
            return; // already applied â€” ack and move on
        const orderRef = db.collection("orders").doc(event.orderId);
        const order = await tx.get(orderRef);
        if (!order.exists)
            return;
        // A payment event only moves an order that is still waiting on payment.
        //
        // Without this, a webhook arriving late â€” after the buyer cancelled, or
        // after the seller already delivered â€” would rewrite the status. A
        // cancelled order silently becoming "confirmed" puts it back in the
        // seller's queue for something the buyer believes they called off, and a
        // delivered order dropping back to "confirmed" would reopen the
        // cancellation window and let the rating be erased.
        //
        // Refunds are the exception: they are legitimately late by nature, and a
        // refund on a delivered order is exactly the case that has to work.
        const current = order.get("status");
        // Matches OrderInternalStatus in the Dart layer. These are the only
        // states where a payment result is still meaningful.
        const awaitingPayment = current === "pendingPayment" ||
            current === "paymentProcessing" ||
            current === "paymentFailed";
        if (event.status !== "refunded" && !awaitingPayment) {
            // Recorded rather than dropped. A provider reporting success on an
            // order we already closed is a reconciliation problem someone needs to
            // see, not noise to swallow.
            tx.update(orderRef, {
                late_payment_event: {
                    status: event.status,
                    payment_id: event.paymentId,
                    order_status_at_receipt: current,
                    received_at: firestore_1.FieldValue.serverTimestamp(),
                },
            });
            tx.set(eventRef, {
                status: "ignored_late",
                order_id: event.orderId,
                provider: provider.id,
                created_at: firestore_1.FieldValue.serverTimestamp(),
            });
            return;
        }
        // Guard against a webhook claiming a different amount than the order.
        // The order total was computed server-side from product documents; if
        // the provider reports something else, something is wrong and we do not
        // silently accept it.
        const expected = order.get("total_minor");
        if (event.status === "succeeded" && event.amountMinor !== expected) {
            tx.update(orderRef, {
                status: "paymentFailed",
                payment_mismatch: {
                    expected,
                    received: event.amountMinor,
                },
                payment_updated_at: firestore_1.FieldValue.serverTimestamp(),
            });
        }
        else {
            tx.update(orderRef, {
                status: event.status === "succeeded"
                    ? "confirmed"
                    : event.status === "refunded"
                        ? "refunded"
                        : "paymentFailed",
                payment_id: event.paymentId,
                payment_provider: provider.id,
                payment_updated_at: firestore_1.FieldValue.serverTimestamp(),
            });
        }
        tx.set(eventRef, {
            status: "completed",
            order_id: event.orderId,
            provider: provider.id,
            created_at: firestore_1.FieldValue.serverTimestamp(),
        });
    });
    // 200 even on a duplicate, or the provider keeps retrying forever.
    res.status(200).send("ok");
});
//# sourceMappingURL=webhook.js.map
