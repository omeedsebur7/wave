import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue, getFirestore, Timestamp } from "firebase-admin/firestore";
import { applyPromo, PromoCode } from "../domain/promoCode";

/** Attempts per hour, per person. */
const MAX_ATTEMPTS_PER_HOUR = 10;

/**
 * Tells a buyer whether a code works, before they commit to an order.
 *
 * The alternative was letting the client read `promo_codes` directly. Firestore's
 * `allow read` covers `list` as well as `get`, so that permission let any
 * signed-in account query the collection and walk away with every code in the
 * system â€” including campaign codes not yet launched.
 *
 * This is still an oracle: ask often enough and you learn which codes exist. The
 * difference is that a callable can be rate-limited and a read rule cannot. Ten
 * attempts an hour makes guessing a six-character code hopeless while leaving
 * plenty of room for someone fixing a typo.
 *
 * It returns the discount it would apply, so the checkout total can move when a
 * code is entered. That figure is a preview â€” `placeOrder` recomputes it against
 * the real cart, because a client-supplied discount is a client-supplied price.
 */
export const validatePromoCode = onCall({ cors: true }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in first");

  const code = String(request.data?.code ?? "").trim().toUpperCase();
  const subtotalMinor = Number(request.data?.subtotalMinor ?? 0);
  const sellerId = String(request.data?.sellerId ?? "");

  if (!code || code.length > 32) {
    throw new HttpsError("invalid-argument", "Invalid code");
  }

  const db = getFirestore();

  // Throttle keyed to the person, not the code.
  //
  // Keying it to the code would let one attacker lock everybody else out of a
  // popular code by exhausting its budget â€” turning an anti-abuse measure into
  // the abuse.
  const attemptsRef = db
    .collection("promo_attempts")
    .doc(uid)
    .collection("attempts");

  const cutoff = Timestamp.fromMillis(
    Date.now() - 60 * 60 * 1000
  );

  const recent = await attemptsRef.where("at", ">", cutoff).count().get();
  if (recent.data().count >= MAX_ATTEMPTS_PER_HOUR) {
    throw new HttpsError(
      "resource-exhausted",
      "Too many code attempts. Try again later."
    );
  }

  // Recorded before the lookup, not after. A crash between the two should
  // over-count rather than under-count: the cost of over-counting is one person
  // waiting, and of under-counting is an unmetered guessing loop.
  await attemptsRef.add({ at: FieldValue.serverTimestamp() });

  const promoRef = db.collection("promo_codes").doc(code);
  const [promoDoc, redemption] = await Promise.all([
    promoRef.get(),
    promoRef.collection("redemptions").doc(uid).get(),
  ]);

  const result = applyPromo({
    promo: promoDoc.exists ? (promoDoc.data() as PromoCode) : null,
    subtotalMinor: Number.isFinite(subtotalMinor) ? subtotalMinor : 0,
    sellerId,
    alreadyUsedByBuyer: redemption.exists,
    nowMs: Date.now(),
  });

  // `not-found`, `inactive` and `exhausted` collapse into one answer on purpose.
  // Distinguishing them tells someone probing which guesses were close â€” that a
  // code exists but is spent is far more useful to an attacker than that it
  // never existed.
  //
  // The rejections that survive are the ones the buyer can act on: expired,
  // already used by them, below the minimum, wrong seller.
  const opaque = new Set(["not-found", "inactive", "exhausted"]);
  const reason =
    result.rejection && opaque.has(result.rejection)
      ? "invalid"
      : result.rejection ?? null;

  return {
    valid: result.rejection === undefined,
    reason,
    discountMinor: result.discountMinor,
  };
});
