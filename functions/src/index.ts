import { initializeApp } from "firebase-admin/app";
initializeApp();

export { signBunnyPlaybackUrl } from "./bunny/signPlaybackUrl";
export {
  createBunnyUploadSlot,
  bunnyVideoStatus,
  publishReel,
} from "./bunny/uploadSlot";
export { placeOrder } from "./orders/placeOrder";
// PAUSED FOR PHASE 1 â€” cash on delivery only, by explicit product decision.
//
// Not deleted. The adapter, the signature verification, the amount check
// against the server-computed total, and the replay protection all stay in the
// tree â€” see functions/src/payments/webhook.ts and providers/zaincash.ts â€”
// because Phase 2 turning this back on should mean uncommenting one export and
// provisioning four secrets, not rebuilding the payment abstraction.
//
// Left commented out rather than exported-but-inert for a concrete reason:
// `paymentWebhook` declares four ZainCash secrets in its `secrets: [...]`
// config. `firebase deploy --only functions` fails at deploy time if those
// secrets are not set in the project â€” so exporting this function would force
// provisioning a ZainCash merchant account before ANY function could ship,
// including the ones with nothing to do with payments. Since `placeOrder` now
// rejects every payment method except "cash_on_delivery" (see the PHASE_1
// guard there), no order can ever reach a state this webhook would need to
// confirm â€” so leaving it unexported costs nothing this phase.
//
// export { paymentWebhook } from "./payments/webhook";
export { recomputeTrustTier } from "./trust/recomputeTrustTier";
export { rankFeed } from "./feed/rankFeed";
export { materializeCounters } from "./counters/materializeShards";
export {
  onFollowChanged,
  onReelWritten,
  onProductWritten,
  onReviewWritten,
  materializeReelFunnel,
} from "./counters/profileStats";
export {
  processAccountDeletion,
  exportMyData,
} from "./privacy/accountDeletion";
export {
  notifyOrderStatus,
  notifyNewOrder,
  notifyReelComment,
  notifyNewRating,
  notifyNewFollower,
  notifyChatMessage,
} from "./notifications/triggers";
export { validatePromoCode } from "./promo/validatePromoCode";
export { enforceRetention } from "./maintenance/retention";
export {
  unlinkDeletedProduct,
  unlinkWithdrawnProduct,
} from "./products/unlinkProduct";
export {
  resolveReport,
  dedupeReport,
  liftSuspension,
} from "./moderation/resolveReport";
export { onPhoneLinked } from "./common/onPhoneLinked";
export { checkOtpAllowance } from "./common/otpGuard";
