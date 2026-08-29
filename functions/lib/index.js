"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.checkOtpAllowance = exports.onPhoneLinked = exports.liftSuspension = exports.dedupeReport = exports.resolveReport = exports.unlinkWithdrawnProduct = exports.unlinkDeletedProduct = exports.enforceRetention = exports.validatePromoCode = exports.notifyChatMessage = exports.notifyNewFollower = exports.notifyNewRating = exports.notifyReelComment = exports.notifyNewOrder = exports.notifyOrderStatus = exports.exportMyData = exports.processAccountDeletion = exports.materializeReelFunnel = exports.onReviewWritten = exports.onProductWritten = exports.onReelWritten = exports.onFollowChanged = exports.materializeCounters = exports.rankFeed = exports.recomputeTrustTier = exports.placeOrder = exports.publishReel = exports.bunnyVideoStatus = exports.createBunnyUploadSlot = exports.signBunnyPlaybackUrl = void 0;
const app_1 = require("firebase-admin/app");
(0, app_1.initializeApp)();
var signPlaybackUrl_1 = require("./bunny/signPlaybackUrl");
Object.defineProperty(exports, "signBunnyPlaybackUrl", { enumerable: true, get: function () { return signPlaybackUrl_1.signBunnyPlaybackUrl; } });
var uploadSlot_1 = require("./bunny/uploadSlot");
Object.defineProperty(exports, "createBunnyUploadSlot", { enumerable: true, get: function () { return uploadSlot_1.createBunnyUploadSlot; } });
Object.defineProperty(exports, "bunnyVideoStatus", { enumerable: true, get: function () { return uploadSlot_1.bunnyVideoStatus; } });
Object.defineProperty(exports, "publishReel", { enumerable: true, get: function () { return uploadSlot_1.publishReel; } });
var placeOrder_1 = require("./orders/placeOrder");
Object.defineProperty(exports, "placeOrder", { enumerable: true, get: function () { return placeOrder_1.placeOrder; } });
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
var recomputeTrustTier_1 = require("./trust/recomputeTrustTier");
Object.defineProperty(exports, "recomputeTrustTier", { enumerable: true, get: function () { return recomputeTrustTier_1.recomputeTrustTier; } });
var rankFeed_1 = require("./feed/rankFeed");
Object.defineProperty(exports, "rankFeed", { enumerable: true, get: function () { return rankFeed_1.rankFeed; } });
var materializeShards_1 = require("./counters/materializeShards");
Object.defineProperty(exports, "materializeCounters", { enumerable: true, get: function () { return materializeShards_1.materializeCounters; } });
var profileStats_1 = require("./counters/profileStats");
Object.defineProperty(exports, "onFollowChanged", { enumerable: true, get: function () { return profileStats_1.onFollowChanged; } });
Object.defineProperty(exports, "onReelWritten", { enumerable: true, get: function () { return profileStats_1.onReelWritten; } });
Object.defineProperty(exports, "onProductWritten", { enumerable: true, get: function () { return profileStats_1.onProductWritten; } });
Object.defineProperty(exports, "onReviewWritten", { enumerable: true, get: function () { return profileStats_1.onReviewWritten; } });
Object.defineProperty(exports, "materializeReelFunnel", { enumerable: true, get: function () { return profileStats_1.materializeReelFunnel; } });
var accountDeletion_1 = require("./privacy/accountDeletion");
Object.defineProperty(exports, "processAccountDeletion", { enumerable: true, get: function () { return accountDeletion_1.processAccountDeletion; } });
Object.defineProperty(exports, "exportMyData", { enumerable: true, get: function () { return accountDeletion_1.exportMyData; } });
var triggers_1 = require("./notifications/triggers");
Object.defineProperty(exports, "notifyOrderStatus", { enumerable: true, get: function () { return triggers_1.notifyOrderStatus; } });
Object.defineProperty(exports, "notifyNewOrder", { enumerable: true, get: function () { return triggers_1.notifyNewOrder; } });
Object.defineProperty(exports, "notifyReelComment", { enumerable: true, get: function () { return triggers_1.notifyReelComment; } });
Object.defineProperty(exports, "notifyNewRating", { enumerable: true, get: function () { return triggers_1.notifyNewRating; } });
Object.defineProperty(exports, "notifyNewFollower", { enumerable: true, get: function () { return triggers_1.notifyNewFollower; } });
Object.defineProperty(exports, "notifyChatMessage", { enumerable: true, get: function () { return triggers_1.notifyChatMessage; } });
var validatePromoCode_1 = require("./promo/validatePromoCode");
Object.defineProperty(exports, "validatePromoCode", { enumerable: true, get: function () { return validatePromoCode_1.validatePromoCode; } });
var retention_1 = require("./maintenance/retention");
Object.defineProperty(exports, "enforceRetention", { enumerable: true, get: function () { return retention_1.enforceRetention; } });
var unlinkProduct_1 = require("./products/unlinkProduct");
Object.defineProperty(exports, "unlinkDeletedProduct", { enumerable: true, get: function () { return unlinkProduct_1.unlinkDeletedProduct; } });
Object.defineProperty(exports, "unlinkWithdrawnProduct", { enumerable: true, get: function () { return unlinkProduct_1.unlinkWithdrawnProduct; } });
var resolveReport_1 = require("./moderation/resolveReport");
Object.defineProperty(exports, "resolveReport", { enumerable: true, get: function () { return resolveReport_1.resolveReport; } });
Object.defineProperty(exports, "dedupeReport", { enumerable: true, get: function () { return resolveReport_1.dedupeReport; } });
Object.defineProperty(exports, "liftSuspension", { enumerable: true, get: function () { return resolveReport_1.liftSuspension; } });
var onPhoneLinked_1 = require("./common/onPhoneLinked");
Object.defineProperty(exports, "onPhoneLinked", { enumerable: true, get: function () { return onPhoneLinked_1.onPhoneLinked; } });
var otpGuard_1 = require("./common/otpGuard");
Object.defineProperty(exports, "checkOtpAllowance", { enumerable: true, get: function () { return otpGuard_1.checkOtpAllowance; } });
//# sourceMappingURL=index.js.map
