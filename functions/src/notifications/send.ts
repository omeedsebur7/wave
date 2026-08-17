import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

/**
 * The one place a notification is sent from.
 *
 * Every send goes through here so three things are guaranteed rather than
 * remembered at each call site:
 *
 * 1. The recipient's channel preference is honoured. The client filters too,
 *    but filtering on the device still costs the user a buzz in their pocket —
 *    the only real respect for "turn this off" is not sending it.
 * 2. A record lands in their notification centre even if the push fails, is
 *    blocked at OS level, or arrives while they are offline. A notification
 *    that exists only as a push is one they lose by glancing away.
 * 3. Dead tokens are cleaned up. A token that has been unregistered will fail
 *    forever otherwise, quietly wasting a send on every future notification.
 *
 * Imports are MODULAR rather than `import * as admin from "firebase-admin"`.
 * Under the installed firebase-admin, `admin.firestore` exists as a callable
 * while `admin.firestore.FieldValue` is undefined — so the serverTimestamp on
 * the notification record threw "Cannot read properties of undefined", the
 * trigger was killed, and every order notification silently never sent. The
 * modular entry points are typed and cannot resolve to undefined.
 */
export type NotificationType =
  | "order_update"
  | "order_placed"
  | "chat_message"
  | "reel_like"
  | "reel_comment"
  | "new_follower"
  | "new_review"
  | "new_rating"
  | "product_back_in_stock"
  | "marketing";

/** Must match NotificationChannel in the Dart layer. */
type Channel = "orders" | "chat" | "social" | "marketing";

const CHANNEL_OF: Record<NotificationType, Channel> = {
  order_update: "orders",
  order_placed: "orders",
  chat_message: "chat",
  reel_like: "social",
  reel_comment: "social",
  new_follower: "social",
  new_review: "social",
  new_rating: "social",
  product_back_in_stock: "social",
  marketing: "marketing",
};

/** Mirrors `NotificationChannel.defaultEnabled` in Dart. */
const DEFAULT_ENABLED: Record<Channel, boolean> = {
  orders: true,
  chat: true,
  social: true,
  marketing: false,
};

export interface SendInput {
  uid: string;
  type: NotificationType;
  title: string;
  body: string;
  /** Ids the client needs to resolve a destination. See NotificationRoute. */
  data?: Record<string, string>;
}

export async function sendNotification(input: SendInput): Promise<void> {
  const db = getFirestore();
  const channel = CHANNEL_OF[input.type];

  // ── 1. Preference check ────────────────────────────────────────────────
  const prefsDoc = await db
    .collection("users")
    .doc(input.uid)
    .collection("notification_prefs")
    .doc("channels")
    .get();

  // Absent means never touched, which is not the same as "off" — fall back to
  // the channel's own default so a user who has never opened settings still
  // gets order updates.
  const enabled = prefsDoc.get(channel) ?? DEFAULT_ENABLED[channel];
  if (enabled === false) return;

  const payload = {
    type: input.type,
    ...(input.data ?? {}),
  };

  // ── 2. The record, written first ───────────────────────────────────────
  // Before the push, deliberately: if the send fails the notification still
  // exists in their centre, which is the durable copy.
  const notificationRef = db
    .collection("users")
    .doc(input.uid)
    .collection("notifications")
    .doc();

  await notificationRef.set({
    channel,
    title: input.title,
    body: input.body,
    read: false,
    deep_link: deepLinkFor(input.type, input.data ?? {}),
    created_at: FieldValue.serverTimestamp(),
  });

  // ── 3. The push ────────────────────────────────────────────────────────
  const tokensSnap = await db
    .collection("users")
    .doc(input.uid)
    .collection("fcm_tokens")
    .get();

  const tokens = tokensSnap.docs.map((d) => d.id);
  if (tokens.length === 0) return;

  // Guarded, and the guard is the point.
  //
  // Point 2 above promises the record survives a failed push. It did not: an
  // unhandled throw here — no FCM emulator, an expired service account, a
  // malformed payload — killed the whole trigger AFTER the record was written
  // but before anything downstream of it ran, and the Firestore trigger that
  // called us reported only "Your function was killed". The durable copy is
  // already saved by this point, so a failed send must be logged and swallowed
  // rather than allowed to take the invocation down with it.
  let response;
  try {
    response = await getMessaging().sendEachForMulticast({
      tokens,
      notification: { title: input.title, body: input.body },
      data: payload,
      android: { priority: channel === "orders" ? "high" : "normal" },
      apns: {
        payload: {
          aps: { sound: channel === "marketing" ? undefined : "default" },
        },
      },
    });
  } catch (error) {
    console.error(
      `Push failed for ${input.uid} (${input.type}); the notification record ` +
        `was already written and remains readable in their centre.`,
      error,
    );
    return;
  }

  // ── 4. Prune dead tokens ───────────────────────────────────────────────
  const dead: string[] = [];
  response.responses.forEach((result, i) => {
    if (result.success) return;
    const code = result.error?.code ?? "";
    // Only these two mean the token is gone for good. A transient network
    // failure must not delete a working token.
    if (
      code === "messaging/registration-token-not-registered" ||
      code === "messaging/invalid-registration-token"
    ) {
      dead.push(tokens[i]);
    }
  });

  if (dead.length > 0) {
    const batch = db.batch();
    for (const token of dead) {
      batch.delete(
        db
          .collection("users")
          .doc(input.uid)
          .collection("fcm_tokens")
          .doc(token)
      );
    }
    await batch.commit();
  }
}

/**
 * Resolves the in-app destination stored on the notification document.
 *
 * Duplicated from `NotificationRoute` in Dart on purpose: the client resolves
 * a live push payload, this resolves the stored record. Keeping both means a
 * notification opened from the centre lands in the same place as one opened
 * from a push.
 */
export function deepLinkFor(
  type: NotificationType,
  data: Record<string, string>
): string | null {
  switch (type) {
    case "order_update":
      return data.order_id ? `/profile/orders/${data.order_id}` : null;
    case "order_placed":
      return "/profile/selling";
    case "chat_message":
      return "/chat";
    case "reel_like":
    case "reel_comment":
      return data.reel_id ? `/reels/${data.reel_id}` : null;
    case "new_follower":
      return data.follower_id ? `/seller/${data.follower_id}` : null;
    case "new_review":
    case "new_rating":
      return "/profile/selling/stats";
    case "product_back_in_stock":
      return data.product_id ? `/marketplace/product/${data.product_id}` : null;
    case "marketing":
      return data.path?.startsWith("/") ? data.path : null;
  }
}