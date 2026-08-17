"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onPhoneLinked = void 0;
const https_1 = require("firebase-functions/v2/https");
const auth_1 = require("firebase-admin/auth");
const firestore_1 = require("firebase-admin/firestore");
/**
 * Flips `phone_verified` after the client completes an OTP link (Â§1, Â§5.2).
 *
 * This exists as a function rather than a client write for one reason: the
 * checkout gate reads this flag. If a client could set it, the gate is
 * decorative. Security Rules block the field from client writes, and this is
 * the only path that sets it â€” and it re-reads the auth record from the Admin
 * SDK rather than trusting anything in the request body.
 */
exports.onPhoneLinked = (0, https_1.onCall)({ cors: true }, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Sign in first");
    }
    const uid = request.auth.uid;
    const user = await (0, auth_1.getAuth)().getUser(uid);
    // The authoritative check: does the auth record actually carry a phone number
    // now? The client claiming so is not evidence.
    if (!user.phoneNumber) {
        throw new https_1.HttpsError("failed-precondition", "No phone number on this account");
    }
    const db = (0, firestore_1.getFirestore)();
    // One number, one account â€” otherwise a single phone farms ratings and trust
    // tiers across as many accounts as someone cares to create.
    //
    // Enforced by a document keyed on the number rather than by a query, for two
    // reasons. A query cannot see a write that has not committed, so two
    // simultaneous verifications of the same number would both find nothing and
    // both succeed. And the number now lives in a subcollection the owner alone
    // can read, so there is no longer a field on `users` to query â€” a query
    // written against the old shape would silently return nothing and let every
    // duplicate through.
    //
    // The id is the E.164 number. That makes this collection a list of every
    // verified number in the system, which is why nothing but a function can read
    // it.
    const claimRef = db.collection("phone_claims").doc(user.phoneNumber);
    await db.runTransaction(async (tx) => {
        const claim = await tx.get(claimRef);
        if (claim.exists && claim.get("uid") !== uid) {
            throw new https_1.HttpsError("already-exists", "This number is already verified on another account");
        }
        tx.set(claimRef, {
            uid,
            claimed_at: firestore_1.FieldValue.serverTimestamp(),
        });
    });
    // The number itself goes in a subcollection only the owner can read.
    //
    // The parent user document is readable by any signed-in account, because the
    // seller page has to show a name, photo, tier and rating to a stranger
    // deciding whether to buy. Firestore cannot return a subset of fields, so a
    // phone number stored alongside them is a phone number handed to everyone.
    await db.collection("users").doc(uid).collection("private").doc("contact").set({
        phone_number: user.phoneNumber,
        updated_at: firestore_1.FieldValue.serverTimestamp(),
    }, { merge: true });
    await db.collection("users").doc(uid).set({
        // The flag stays public: it is a trust signal a buyer may reasonably see,
        // and it reveals nothing beyond "this account verified a number".
        phone_verified: true,
        phone_verified_at: firestore_1.FieldValue.serverTimestamp(),
    }, { merge: true });
    return { verified: true };
});
//# sourceMappingURL=onPhoneLinked.js.map