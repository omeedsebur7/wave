"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.notifyChatMessage = exports.notifyNewFollower = exports.notifyNewRating = exports.notifyReelComment = exports.notifyNewOrder = exports.notifyOrderStatus = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const firestore_2 = require("firebase-admin/firestore");
const send_1 = require("./send");
/**
 * Order status changes, to the buyer.
 *
 * Only the three stages the customer actually sees (Â§5.2). Notifying on every
 * internal transition would mean a buzz for "packed" and another for "handed to
 * courier" â€” the exact over-notification that drives early uninstalls, and a
 * contradiction of the simplified tracker.
 */
exports.notifyOrderStatus = (0, firestore_1.onDocumentUpdated)("orders/{orderId}", async (event) => {
    const before = event.data?.before.get("status");
    const after = event.data?.after.get("status");
    if (!after || before === after)
        return;
    const buyerId = event.data?.after.get("buyer_id");
    const orderId = event.params.orderId;
    const message = customerFacingMessage(after);
    if (!message)
        return; // an internal-only transition
    await (0, send_1.sendNotification)({
        uid: buyerId,
        type: "order_update",
        title: message.title,
        body: message.body,
        data: { order_id: orderId },
    });
});
function customerFacingMessage(status) {
    switch (status) {
        case "confirmed":
            return {
                title: "Order confirmed",
                body: "The seller has your order and is getting it ready.",
            };
        case "handedToCourier":
            return {
                title: "On the way",
                body: "Your order has left the seller. The courier will call you.",
            };
        case "delivered":
            return {
                title: "Delivered",
                body: "Enjoy it. Rating the seller helps the next buyer.",
            };
        case "cancelled":
            return {
                title: "Order cancelled",
                body: "Anything paid is refunded to the original method.",
            };
        default:
            // packed, outForDelivery, payment states â€” real, and none of the
            // buyer's business.
            return null;
    }
}
/** A new order, to the seller. The one notification they most need. */
exports.notifyNewOrder = (0, firestore_1.onDocumentCreated)("orders/{orderId}", async (event) => {
    const sellerId = event.data?.get("seller_id");
    if (!sellerId)
        return;
    const items = event.data?.get("items") ?? [];
    const first = items[0]?.title ?? "an item";
    await (0, send_1.sendNotification)({
        uid: sellerId,
        type: "order_placed",
        title: "You sold something",
        body: items.length > 1
            ? `${first} and ${items.length - 1} more. Pack it when you can.`
            : `${first}. Pack it when you can.`,
        data: { order_id: event.params.orderId },
    });
});
/**
 * A comment, to the Reel's author.
 *
 * In a Reels-to-purchase funnel a comment is usually a pre-purchase question,
 * so an unanswered one is a lost sale. That is why this is an order-grade
 * signal rather than ordinary social noise.
 */
exports.notifyReelComment = (0, firestore_1.onDocumentCreated)("reels/{reelId}/comments/{commentId}", async (event) => {
    const db = (0, firestore_2.getFirestore)();
    const reelId = event.params.reelId;
    const reel = await db.collection("reels").doc(reelId).get();
    const authorId = reel.get("author_id");
    const commenterId = event.data?.get("author_id");
    // Never notify someone about their own action.
    if (!authorId || authorId === commenterId)
        return;
    const commenterName = event.data?.get("author_name") ?? "Someone";
    const text = String(event.data?.get("text") ?? "");
    await (0, send_1.sendNotification)({
        uid: authorId,
        type: "reel_comment",
        title: `${commenterName} commented`,
        // Truncated: a notification is a summary, and the full text is one tap
        // away.
        body: text.length > 100 ? `${text.slice(0, 97)}â€¦` : text,
        data: { reel_id: reelId },
    });
});
/// A seller rating, to the seller.
///
/// Shares a trigger path with `recomputeTrustTier`. That is intentional and
/// safe: they touch different fields on the user document and Firestore merges
/// concurrent field-level writes. Combining them would couple a notification
/// failure to a tier calculation, and a push that fails to send must not
/// prevent a badge from updating.
exports.notifyNewRating = (0, firestore_1.onDocumentCreated)("seller_ratings/{ratingId}", async (event) => {
    const sellerId = event.data?.get("seller_id");
    const rating = Number(event.data?.get("rating") ?? 0);
    if (!sellerId)
        return;
    await (0, send_1.sendNotification)({
        uid: sellerId,
        type: "new_rating",
        title: `You got ${rating} star${rating === 1 ? "" : "s"}`,
        body: "Your rating and tier have been updated.",
    });
});
/// A new follower. Shares its path with `onFollowChanged` for the same reason
/// as above â€” one counts, one notifies, and neither should block the other.
exports.notifyNewFollower = (0, firestore_1.onDocumentCreated)("users/{uid}/following/{sellerId}", async (event) => {
    const followerId = event.params.uid;
    const sellerId = event.params.sellerId;
    if (followerId === sellerId)
        return;
    const follower = await (0, firestore_2.getFirestore)()
        .collection("users")
        .doc(followerId)
        .get();
    await (0, send_1.sendNotification)({
        uid: sellerId,
        type: "new_follower",
        title: "New follower",
        body: `${follower.get("display_name") ?? "Someone"} is following you.`,
        data: { follower_id: followerId },
    });
});
/** A chat message, to whoever did not send it. */
exports.notifyChatMessage = (0, firestore_1.onDocumentCreated)("conversations/{conversationId}/messages/{messageId}", async (event) => {
    const db = (0, firestore_2.getFirestore)();
    const conversationId = event.params.conversationId;
    const conversation = await db
        .collection("conversations")
        .doc(conversationId)
        .get();
    const participants = conversation.get("participant_ids") ?? [];
    const senderId = event.data?.get("sender_id");
    const recipientId = participants.find((id) => id !== senderId);
    if (!recipientId)
        return;
    const names = conversation.get("participant_names") ?? {};
    const text = String(event.data?.get("text") ?? "");
    await (0, send_1.sendNotification)({
        uid: recipientId,
        type: "chat_message",
        title: names[senderId] ?? "New message",
        body: text.length > 100 ? `${text.slice(0, 97)}â€¦` : text,
    });
});
//# sourceMappingURL=triggers.js.map