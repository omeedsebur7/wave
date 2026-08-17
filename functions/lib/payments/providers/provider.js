"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.CashOnDeliveryProvider = void 0;
/**
 * Cash on delivery.
 *
 * Not a degraded fallback — it is the primary rail in this market, and
 * modelling it as a provider rather than an `if (cash)` branch keeps the order
 * flow identical whether money moves now or at the door.
 */
class CashOnDeliveryProvider {
    id = "cash_on_delivery";
    async createPayment(input) {
        // Nothing to charge yet. The order is confirmed immediately; the money
        // arrives with the courier.
        return {
            paymentId: `cod_${input.orderId}`,
            status: "succeeded",
        };
    }
    verifyWebhook() {
        return null; // there is no gateway to call back
    }
    async refund() {
        // Nothing was taken. A cancelled COD order simply is not collected.
    }
}
exports.CashOnDeliveryProvider = CashOnDeliveryProvider;
//# sourceMappingURL=provider.js.map