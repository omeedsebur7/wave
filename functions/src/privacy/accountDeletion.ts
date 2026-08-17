import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getAuth } from "firebase-admin/auth";
import { FieldValue, Firestore, getFirestore, Query } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";

/**
 * Right to be forgotten (Â§7).
 *
 * The hard question in a marketplace is not "how do we delete a user" but
 * "what must survive them". A completed order is a shared record: the SELLER
 * needs it for their own accounts, tax obligations and dispute history, and
 * they have a legitimate interest in it that does not evaporate because the
 * buyer left. Most data-protection regimes recognise this â€” erasure is not
 * absolute where another party has a lawful basis to retain.
 *
 * So the rule here is: delete everything that identifies the person, and
 * pseudonymise the transaction records rather than destroying them. The order
 * survives with its amounts and dates intact; the name, phone, and address on
 * it do not.
 *
 * This is stated plainly in the deletion dialog in the app, because a promise
 * of total erasure that we cannot keep is worse than an honest partial one.
 */
export const processAccountDeletion = onDocumentCreated(
  "deletion_requests/{uid}",
  async (event) => {
    const uid = event.params.uid;
    const db = getFirestore();

    // â”€â”€ 1. Hard-delete everything owned solely by this person â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    const ownedSubcollections = [
      "addresses",
      "payment_methods",
      "saved_reels",
      "favourites",
      "notifications",
      "notification_prefs",
      "fcm_tokens",
      "following",
    ];

    for (const name of ownedSubcollections) {
      await deleteCollection(db, `users/${uid}/${name}`);
    }

    // Their Reels and listings go too â€” content, not shared record.
    await deleteQuery(db.collection("reels").where("author_id", "==", uid));
    await deleteQuery(db.collection("products").where("seller_id", "==", uid));
    await deleteCollection(db, `blocks/${uid}/blocked`);

    // Their write-throttle document. Small, but leaving it behind means a
    // deleted account's cooldown timestamps outlive the account, and a uid can
    // in principle be observed again.
    await db.collection("rate_limits").doc(uid).delete();

    // Release their phone number claim, or the number is burned: they could
    // never re-register with it, and neither could anyone who later gets that
    // number reassigned by the carrier â€” which happens.
    const claims = await db
      .collection("phone_claims")
      .where("uid", "==", uid)
      .get();
    for (const claim of claims.docs) {
      await claim.ref.delete();
    }

    // Buy Now taps they made. These are behavioural records tied to a person,
    // not a commercial record between two parties, so they go with the account
    // rather than being pseudonymised. The Reel's aggregate total is already
    // materialised and is not affected.
    await deleteQuery(
      db.collectionGroup("buy_now_taps").where("user_id", "==", uid)
    );

    // Reports they filed leave the queue with them, EXCEPT any that led to a
    // suspension â€” that report is the record behind a decision affecting a third
    // party, and deleting it would remove the justification for an action still
    // in force. Pseudonymised instead.
    await deleteQuery(
      db.collection("reports")
        .where("reporter_id", "==", uid)
        .where("action", "in", ["pending", "merged", "dismissed"])
    );
    await pseudonymise(
      db.collection("reports").where("reporter_id", "==", uid)
    );

    // â”€â”€ 2. Pseudonymise what a counterparty legitimately keeps â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    // Reviews and ratings stay, because removing them would silently rewrite a
    // seller's trust score â€” the next buyer would be shown a rating built on
    // evidence that no longer exists.
    await pseudonymise(db.collection("reviews").where("author_id", "==", uid));
    await pseudonymise(
      db.collection("seller_ratings").where("author_id", "==", uid)
    );

    // Comments keep their text (they are part of a public thread others
    // replied to) but lose the author's identity.
    await pseudonymiseCollectionGroup(db, "comments", uid);

    // Orders: strip the personal fields, keep the commercial record.
    //
    // Delivery details are handled differently depending on whether the order
    // is finished, because there are two people's interests here and they point
    // opposite ways.
    //
    // On a FINISHED order the delivery details serve nobody: the parcel arrived,
    // and what remains is the coordinates of somebody's home on a record they
    // asked to be forgotten from. Stripped immediately.
    //
    // On an IN-FLIGHT order a courier is holding a parcel. Erasing the address
    // mid-delivery does not protect the person â€” the courier already has it â€”
    // it just strands the seller with an order they cannot complete, and
    // cancelling it would count against their fulfilment tier for something
    // entirely outside their control. Kept until the order reaches a terminal
    // state, then stripped by the retention sweep.
    const asBuyer = await db
      .collection("orders")
      .where("buyer_id", "==", uid)
      .get();

    const TERMINAL = ["delivered", "cancelled", "refunded"];

    const batch = db.batch();
    for (const order of asBuyer.docs) {
      const finished = TERMINAL.includes(order.get("status") as string);

      batch.update(order.ref, {
        buyer_id: `deleted_${uid.slice(0, 8)}`,
        buyer_name: "Deleted account",
        buyer_deleted_at: FieldValue.serverTimestamp(),
        ...(finished
          ? {
              buyer_phone: FieldValue.delete(),
              address_id: FieldValue.delete(),
              delivery_address: FieldValue.delete(),
              // The map pin. Added after this cascade was written, and missed
              // by it â€” a more precise home address than the text field beside
              // it, surviving a deletion that promised to remove addresses.
              delivery_location: FieldValue.delete(),
            }
          : {
              // Marks it for the sweep. Without this the pin would survive
              // indefinitely on any order that happened to be in flight.
              delivery_details_pending_erasure: true,
            }),
      });
    }
    await batch.commit();

    // â”€â”€ 3. Remove the profile and the auth record, in that order â”€â”€â”€â”€â”€â”€â”€â”€â”€
    // Profile first: if auth deletion fails, a retry still finds the request
    // document and can finish the job. The reverse order can leave an
    // orphaned profile nobody can sign in to clean up.
    await db.collection("users").doc(uid).delete();

    // Storage: avatars and product images.
    const bucket = getStorage().bucket();
    await bucket.deleteFiles({ prefix: `avatars/${uid}/` });
    await bucket.deleteFiles({ prefix: `products/${uid}/` });

    try {
      await getAuth().deleteUser(uid);
    } catch (e) {
      // Already gone is success, not failure.
      console.warn(`Auth record for ${uid} already removed`, e);
    }

    await event.data?.ref.update({
      status: "completed",
      completed_at: FieldValue.serverTimestamp(),
    });
  }
);

/**
 * Data export (Â§7).
 *
 * Returns everything we hold about the caller, as JSON, in one call. Assembled
 * on demand rather than pre-generated: an export is rare, and a stale
 * pre-generated file is a privacy problem of its own.
 */
export const exportMyData = onCall({ cors: true }, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in first");

  const uid = request.auth.uid;
  const db = getFirestore();

  const profile = await db.collection("users").doc(uid).get();

  const [orders, reels, products, reviews, ratings, addresses] =
    await Promise.all([
      db.collection("orders").where("buyer_id", "==", uid).get(),
      db.collection("reels").where("author_id", "==", uid).get(),
      db.collection("products").where("seller_id", "==", uid).get(),
      db.collection("reviews").where("author_id", "==", uid).get(),
      db.collection("seller_ratings").where("author_id", "==", uid).get(),
      db.collection("users").doc(uid).collection("addresses").get(),
    ]);

  return {
    exported_at: new Date().toISOString(),
    profile: profile.data() ?? null,
    orders: orders.docs.map((d) => ({ id: d.id, ...d.data() })),
    reels: reels.docs.map((d) => ({ id: d.id, ...d.data() })),
    products: products.docs.map((d) => ({ id: d.id, ...d.data() })),
    reviews: reviews.docs.map((d) => ({ id: d.id, ...d.data() })),
    seller_ratings: ratings.docs.map((d) => ({ id: d.id, ...d.data() })),
    addresses: addresses.docs.map((d) => ({ id: d.id, ...d.data() })),
    // Named explicitly so the export is honest about its own boundaries.
    not_included: [
      "Video files, which are held by our video provider and are deleted with your Reels",
      "Payment card details, which are held by the payment provider and never by WAVE",
    ],
  };
});

// â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/** Batched delete. Firestore caps a write batch at 500 operations. */
async function deleteCollection(
  db: Firestore,
  path: string,
  batchSize = 400
): Promise<void> {
  const ref = db.collection(path);
  for (;;) {
    const snap = await ref.limit(batchSize).get();
    if (snap.empty) return;
    const batch = db.batch();
    snap.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
    if (snap.size < batchSize) return;
  }
}

async function deleteQuery(
  query: Query,
  batchSize = 400
): Promise<void> {
  for (;;) {
    const snap = await query.limit(batchSize).get();
    if (snap.empty) return;
    const batch = snap.docs[0].ref.firestore.batch();
    snap.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
    if (snap.size < batchSize) return;
  }
}

/** Keeps the record, removes the person. */
async function pseudonymise(query: Query): Promise<void> {
  const snap = await query.get();
  if (snap.empty) return;

  const batch = snap.docs[0].ref.firestore.batch();
  for (const doc of snap.docs) {
    batch.update(doc.ref, {
      author_id: "deleted",
      author_name: "Deleted account",
      author_avatar_url: FieldValue.delete(),
    });
  }
  await batch.commit();
}

async function pseudonymiseCollectionGroup(
  db: Firestore,
  group: string,
  uid: string
): Promise<void> {
  const snap = await db
    .collectionGroup(group)
    .where("author_id", "==", uid)
    .get();
  if (snap.empty) return;

  const batch = db.batch();
  for (const doc of snap.docs) {
    batch.update(doc.ref, {
      author_id: "deleted",
      author_name: "Deleted account",
      author_avatar_url: FieldValue.delete(),
    });
  }
  await batch.commit();
}
