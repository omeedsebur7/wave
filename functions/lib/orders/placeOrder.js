"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.placeOrder = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const orderTotals_1 = require("../domain/orderTotals");
const promoCode_1 = require("../domain/promoCode");
const deliveryLocation_1 = require("../domain/deliveryLocation");
/**
 * Order placement.
 *
 * Guarantees:
 * 1. Prices and stock are read from Firestore, never trusted from the client.
 * 2. The idempotency key is handled atomically.
 * 3. All Firestore transaction reads happen before writes.
 * 4. Phase 1 accepts cash on delivery only.
 * 5. deliveryLocation is optional for the current integration tests.
 *
 * Imports are MODULAR — `getFirestore` and `FieldValue` from
 * "firebase-admin/firestore" — not `import * as admin from "firebase-admin"`.
 *
 * That was not a style preference. Under the installed firebase-admin,
 * `admin.firestore` exists as a callable (so `admin.firestore()` returned a
 * working db) while `admin.firestore.FieldValue` was undefined. Every
 * `FieldValue.increment` and `serverTimestamp` therefore threw
 * "Cannot read properties of undefined", inside the transaction, where it
 * became a plain TypeError rather than an HttpsError — so the client only ever
 * saw `[firebase_functions/internal] INTERNAL` with no message, and the real
 * stack existed solely in the emulator log. The modular entry points are typed
 * and cannot silently resolve to undefined.
 */
exports.placeOrder = (0, https_1.onCall)({ cors: true }, async (request) => {
    const db = (0, firestore_1.getFirestore)();
    // ─────────────────────────────────────────────────────────────────────
    // AUTH
    // ─────────────────────────────────────────────────────────────────────
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Sign in to place an order");
    }
    const uid = request.auth.uid;
    if (request.auth.token.firebase?.sign_in_provider ===
        "anonymous") {
        throw new https_1.HttpsError("permission-denied", "Guests cannot place orders");
    }
    // ─────────────────────────────────────────────────────────────────────
    // INPUT
    // ─────────────────────────────────────────────────────────────────────
    const { idempotencyKey, items, addressId, paymentMethodId, sourceReelId, promoCode, deliveryLocation, } = request.data ?? {};
    if (typeof idempotencyKey !== "string" ||
        idempotencyKey.trim().length < 8) {
        throw new https_1.HttpsError("invalid-argument", 
        // Says which of the two it was. "Missing idempotency key" for a key that
        // was present but five characters long sent a test hunting for a wiring
        // fault that did not exist.
        typeof idempotencyKey === "string"
            ? "Idempotency key must be at least 8 characters"
            : "Missing idempotency key");
    }
    if (!Array.isArray(items) || items.length === 0) {
        throw new https_1.HttpsError("invalid-argument", "Cart is empty");
    }
    if (typeof paymentMethodId !== "string" ||
        paymentMethodId.trim().length === 0) {
        throw new https_1.HttpsError("invalid-argument", "Payment method is required");
    }
    const cleanIdempotencyKey = idempotencyKey.trim();
    const cleanPaymentMethodId = paymentMethodId.trim();
    // ─────────────────────────────────────────────────────────────────────
    // PHASE 1 PAYMENT GATE
    // ─────────────────────────────────────────────────────────────────────
    const PHASE_1_ALLOWED_PAYMENT_METHODS = new Set([
        "cash_on_delivery",
    ]);
    if (!PHASE_1_ALLOWED_PAYMENT_METHODS.has(cleanPaymentMethodId)) {
        throw new https_1.HttpsError("failed-precondition", "Only cash on delivery is available right now");
    }
    // ─────────────────────────────────────────────────────────────────────
    // PHONE VERIFICATION
    // ─────────────────────────────────────────────────────────────────────
    const userSnap = await db
        .collection("users")
        .doc(uid)
        .get();
    if (userSnap.get("phone_verified") !== true) {
        throw new https_1.HttpsError("failed-precondition", "A verified phone number is required before your first order");
    }
    const keyRef = db
        .collection("idempotency_keys")
        .doc(cleanIdempotencyKey);
    // ─────────────────────────────────────────────────────────────────────
    // TRANSACTION
    // ─────────────────────────────────────────────────────────────────────
    const orderId = await db.runTransaction(async (tx) => {
        // ---------------------------------------------------------------
        // READ #1: IDEMPOTENCY KEY
        // ---------------------------------------------------------------
        const existing = await tx.get(keyRef);
        if (existing.exists) {
            const status = existing.get("status");
            if (status === "completed") {
                const existingOrderId = existing.get("order_id");
                if (typeof existingOrderId !== "string" ||
                    existingOrderId.length === 0) {
                    throw new https_1.HttpsError("internal", "Idempotency record is invalid");
                }
                return existingOrderId;
            }
            throw new https_1.HttpsError("aborted", "This order is already being processed");
        }
        // ---------------------------------------------------------------
        // READ #2: PRODUCTS
        // ---------------------------------------------------------------
        const snapshots = new Map();
        for (const rawItem of items) {
            if (rawItem == null ||
                typeof rawItem !== "object") {
                throw new https_1.HttpsError("invalid-argument", "Invalid cart item");
            }
            const productId = rawItem.productId;
            if (typeof productId !== "string" ||
                productId.trim().length === 0) {
                throw new https_1.HttpsError("invalid-argument", "Invalid product id");
            }
            const cleanProductId = productId.trim();
            const productRef = db
                .collection("products")
                .doc(cleanProductId);
            const product = await tx.get(productRef);
            if (!product.exists) {
                throw new https_1.HttpsError("not-found", `Product ${cleanProductId} not found`);
            }
            snapshots.set(product.id, {
                productId: product.id,
                title: product.get("title") ?? "",
                sellerId: product.get("seller_id") ?? "",
                priceMinor: Number(product.get("price_minor") ?? 0),
                currency: product.get("currency") ?? "IQD",
                stock: Number(product.get("stock") ?? 0),
                imageUrl: product.get("image_url") ?? "",
            });
        }
        // ---------------------------------------------------------------
        // COMPUTE ORDER
        // ---------------------------------------------------------------
        let computed;
        try {
            computed = (0, orderTotals_1.computeOrder)(items.map((item) => ({
                productId: item.productId,
                quantity: Number(item.quantity ?? 1),
            })), snapshots, uid);
        }
        catch (error) {
            if (error instanceof orderTotals_1.OrderComputationError) {
                throw new https_1.HttpsError(error.code, error.message);
            }
            // Carries the original message rather than swallowing it. A bare
            // "Could not compute order" is indistinguishable from an unhandled
            // TypeError once it reaches the client, which is how one of these
            // stayed invisible for an entire debugging session.
            throw new https_1.HttpsError("internal", `Could not compute order: ${error instanceof Error ? error.message : String(error)}`);
        }
        // ---------------------------------------------------------------
        // READ #3: PROMO
        //
        // All reads are completed before any transaction write.
        // ---------------------------------------------------------------
        let discountMinor = 0;
        let appliedPromo = null;
        let promoDoc = null;
        let usedRef = null;
        let alreadyUsed = false;
        if (typeof promoCode === "string" &&
            promoCode.trim().length > 0) {
            const normalisedPromo = promoCode.trim().toUpperCase();
            promoDoc = await tx.get(db
                .collection("promo_codes")
                .doc(normalisedPromo));
            usedRef = db
                .collection("promo_codes")
                .doc(normalisedPromo)
                .collection("redemptions")
                .doc(uid);
            const usedSnap = await tx.get(usedRef);
            alreadyUsed = usedSnap.exists;
            const promo = promoDoc.exists
                ? promoDoc.data()
                : null;
            const result = (0, promoCode_1.applyPromo)({
                promo,
                subtotalMinor: computed.totalMinor,
                sellerId: computed.sellerId,
                alreadyUsedByBuyer: alreadyUsed,
                nowMs: Date.now(),
            });
            if (result.rejection) {
                throw new https_1.HttpsError("failed-precondition", `promo:${result.rejection}`);
            }
            discountMinor = result.discountMinor;
            appliedPromo = normalisedPromo;
        }
        // ---------------------------------------------------------------
        // DELIVERY LOCATION
        // ---------------------------------------------------------------
        let pin = null;
        if (deliveryLocation != null) {
            try {
                pin = (0, deliveryLocation_1.normaliseLocation)(deliveryLocation);
            }
            catch (error) {
                if (error instanceof orderTotals_1.OrderComputationError) {
                    throw new https_1.HttpsError(error.code, error.message);
                }
                throw new https_1.HttpsError("invalid-argument", "Invalid delivery location");
            }
        }
        // ───────────────────────────────────────────────────────────────
        // WRITES ONLY FROM HERE
        // ───────────────────────────────────────────────────────────────
        // ---------------------------------------------------------------
        // WRITE #1: STOCK
        // ---------------------------------------------------------------
        for (const line of computed.items) {
            tx.update(db
                .collection("products")
                .doc(line.product_id), {
                stock: firestore_1.FieldValue.increment(-line.quantity),
            });
        }
        // ---------------------------------------------------------------
        // WRITE #2: PROMO REDEMPTION
        // ---------------------------------------------------------------
        if (appliedPromo !== null &&
            promoDoc !== null &&
            usedRef !== null &&
            !alreadyUsed) {
            tx.set(usedRef, {
                uid,
                redeemed_at: firestore_1.FieldValue.serverTimestamp(),
            });
            tx.update(promoDoc.ref, {
                redemption_count: firestore_1.FieldValue.increment(1),
            });
        }
        // ---------------------------------------------------------------
        // WRITE #3: ORDER
        // ---------------------------------------------------------------
        const orderRef = db
            .collection("orders")
            .doc();
        tx.set(orderRef, {
            id: orderRef.id,
            buyer_id: uid,
            seller_id: computed.sellerId,
            items: computed.items,
            product_ids: computed.productIds,
            subtotal_minor: computed.totalMinor,
            discount_minor: discountMinor,
            total_minor: computed.totalMinor - discountMinor,
            promo_code: appliedPromo,
            currency: computed.currency,
            status: "confirmed",
            address_id: typeof addressId === "string"
                ? addressId
                : null,
            payment_method_id: cleanPaymentMethodId,
            source_reel_id: sourceReelId ?? null,
            delivery_location: pin,
            idempotency_key: cleanIdempotencyKey,
            has_been_rated: false,
            created_at: firestore_1.FieldValue.serverTimestamp(),
        });
        // ---------------------------------------------------------------
        // WRITE #4: IDEMPOTENCY RECORD
        // ---------------------------------------------------------------
        tx.set(keyRef, {
            status: "completed",
            order_id: orderRef.id,
            uid,
            created_at: firestore_1.FieldValue.serverTimestamp(),
        });
        return orderRef.id;
    });
    // ─────────────────────────────────────────────────────────────────────
    // READ BACK ORDER
    // ─────────────────────────────────────────────────────────────────────
    const orderSnap = await db
        .collection("orders")
        .doc(orderId)
        .get();
    if (!orderSnap.exists) {
        throw new https_1.HttpsError("internal", "Order was created but could not be read back");
    }
    return {
        id: orderId,
        ...orderSnap.data(),
    };
});
//# sourceMappingURL=placeOrder.js.map