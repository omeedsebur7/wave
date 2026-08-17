"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.publishReel = exports.bunnyVideoStatus = exports.createBunnyUploadSlot = void 0;
const https_1 = require("firebase-functions/v2/https");
const params_1 = require("firebase-functions/params");
const firestore_1 = require("firebase-admin/firestore");
const BUNNY_API_KEY = (0, params_1.defineSecret)("BUNNY_API_KEY");
const BUNNY_LIBRARY_ID = (0, params_1.defineSecret)("BUNNY_LIBRARY_ID");
/**
 * Base URL for the Bunny Stream REST API.
 *
 * Overridable ONLY so integration tests can point it at a local stub. It is
 * read from the environment rather than a secret because it is not one — it is
 * a hostname, and the emulator has no way to inject a fetch() target otherwise.
 *
 * Why this exists: integration_test/helpers/fake_bunny.dart was a Dart object
 * living in the test process, while this function called video.bunnycdn.com
 * from the Functions runtime. There was no path between them. So
 * `expect(bunny.videoCount, 0)` — meant to prove no Bunny video is created for
 * a rejected duration — passed because the fake was never touched, and would
 * have passed identically if this function had created ten real billed videos.
 * A stub that nothing routes to tests nothing.
 *
 * In production the variable is unset and this is video.bunnycdn.com. If it is
 * ever set in a deployed environment, that is a misconfiguration: every upload
 * would be handed a URL pointing somewhere that is not Bunny.
 */
const BUNNY_API_BASE = process.env.BUNNY_API_BASE ?? "https://video.bunnycdn.com";
/**
 * Creates a Bunny video object and hands back a scoped upload URL.
 *
 * The device uploads bytes DIRECTLY to Bunny — never through this function.
 * Proxying video through Cloud Functions would be slow, hit request size
 * limits, and cost egress twice, all for no security gain: the URL returned
 * here is already scoped to one video object that only this user owns.
 *
 * The Bunny API key stays server-side for the same reason the playback signing
 * key does. A key in an app binary is a public key.
 *
 * The compensating delete below is now reachable in tests: the stub's
 * /__control/fail-next-create and /__control/reject-delete endpoints exercise
 * both the orphan path and the both-failed path that only logs. It previously
 * carried a VERIFICATION NOTE saying it had never been executed; that note is
 * discharged by test coverage rather than by inspection, which is the only way
 * to actually discharge it.
 */
exports.createBunnyUploadSlot = (0, https_1.onCall)({ secrets: [BUNNY_API_KEY, BUNNY_LIBRARY_ID], cors: true }, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Sign in to publish");
    }
    if (request.auth.token.firebase?.sign_in_provider === "anonymous") {
        throw new https_1.HttpsError("permission-denied", "Guests cannot publish");
    }
    const uid = request.auth.uid;
    const durationSeconds = Number(request.data?.durationSeconds ?? 0);
    // Server-side duration cap. The client checks too, but only this check
    // counts — a modified client could send anything.
    //
    // Ordered BEFORE the Bunny call on purpose: a rejected duration must not
    // create a billed video object. The stub's video count is what proves it.
    if (durationSeconds <= 0 || durationSeconds > 60) {
        throw new https_1.HttpsError("invalid-argument", "Reels must be 60 seconds or less");
    }
    // Publish rate limit. Without this, one script can fill a video library.
    const db = (0, firestore_1.getFirestore)();
    const since = firestore_1.Timestamp.fromMillis(Date.now() - 60 * 60 * 1000);
    const recent = await db
        .collection("reels")
        .where("author_id", "==", uid)
        .where("created_at", ">", since)
        .count()
        .get();
    if (recent.data().count >= 10) {
        throw new https_1.HttpsError("resource-exhausted", "You have posted a lot in the last hour. Try again later.");
    }
    const libraryId = BUNNY_LIBRARY_ID.value();
    const created = await fetch(`${BUNNY_API_BASE}/library/${libraryId}/videos`, {
        method: "POST",
        headers: {
            AccessKey: BUNNY_API_KEY.value(),
            "Content-Type": "application/json",
        },
        body: JSON.stringify({ title: String(request.data?.title ?? "Reel") }),
    });
    if (!created.ok) {
        // Carries the status through. "Could not create the video" alone is the
        // same message for a missing API key, a rate limit, and a malformed
        // library id — and the first of those is what an unconfigured emulator
        // produces, so the message a developer sees most often was the least
        // informative one available.
        throw new https_1.HttpsError("internal", `Could not create the video (Bunny returned ${created.status})`);
    }
    const video = (await created.json());
    // Claim the video against this user before returning it, so publishReel
    // can verify ownership later and nobody can publish someone else's upload.
    try {
        await db.collection("pending_uploads").doc(video.guid).set({
            uid,
            duration_seconds: durationSeconds,
            created_at: firestore_1.FieldValue.serverTimestamp(),
        });
    }
    catch (writeError) {
        // Compensating delete.
        //
        // Without this, a Firestore blip landing right here — after Bunny has
        // already created a real, billed video object, before this function
        // could record who it belongs to — leaves an orphan: a video nobody in
        // this system owns, that no cleanup job knows to look for, that sits on
        // Bunny forever accruing storage cost. The person who tried to publish
        // just sees a failed request and tries again, which creates a SECOND
        // video and leaves the first orphaned regardless.
        //
        // This is best-effort. If the delete call itself also fails — Bunny is
        // down at exactly the moment Firestore is too, which is rare but not
        // impossible — the orphan is logged rather than silently accepted, so
        // it can be found and removed by hand rather than never being found at
        // all. A function that swallowed both failures would turn a rare,
        // diagnosable leak into an invisible one.
        try {
            const deleted = await fetch(`${BUNNY_API_BASE}/library/${libraryId}/videos/${video.guid}`, { method: "DELETE", headers: { AccessKey: BUNNY_API_KEY.value() } });
            // A non-2xx here is the same outcome as a thrown fetch: the video is
            // still there. It was previously treated as success purely because it
            // did not throw, so a wrong verb or path would have logged nothing and
            // looked like it cleaned up.
            if (!deleted.ok) {
                throw new Error(`Bunny returned ${deleted.status}`);
            }
        }
        catch (cleanupError) {
            console.error(`Orphaned Bunny video ${video.guid} in library ${libraryId}: ` +
                `ownership record failed to write (${writeError}) and the ` +
                `compensating delete also failed (${cleanupError}). ` +
                `Remove it manually via the Bunny dashboard.`);
        }
        throw new https_1.HttpsError("internal", "Could not finish setting up the upload. Please try again.");
    }
    return {
        videoId: video.guid,
        uploadUrl: `${BUNNY_API_BASE}/library/${libraryId}/videos/${video.guid}`,
    };
});
/** Polled by the client while Bunny transcodes. */
exports.bunnyVideoStatus = (0, https_1.onCall)({ secrets: [BUNNY_API_KEY, BUNNY_LIBRARY_ID], cors: true }, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Sign in first");
    }
    const videoId = String(request.data?.videoId ?? "");
    if (!/^[a-zA-Z0-9-]+$/.test(videoId)) {
        throw new https_1.HttpsError("invalid-argument", "Invalid videoId");
    }
    const res = await fetch(`${BUNNY_API_BASE}/library/${BUNNY_LIBRARY_ID.value()}/videos/${videoId}`, { headers: { AccessKey: BUNNY_API_KEY.value() } });
    if (!res.ok)
        throw new https_1.HttpsError("internal", "Could not read video status");
    // Bunny status codes: 4 = finished, 5 = failed.
    const video = (await res.json());
    return { ready: video.status === 4, failed: video.status === 5 };
});
/**
 * Writes the Reel document once the video is genuinely playable.
 *
 * Separate from the upload slot deliberately: a Reel that exists before its
 * rendition ladder does is a Reel the feed will show and fail to play, which
 * is a worse experience than a slightly delayed post.
 */
exports.publishReel = (0, https_1.onCall)({ cors: true }, async (request) => {
    if (!request.auth)
        throw new https_1.HttpsError("unauthenticated", "Sign in first");
    const db = (0, firestore_1.getFirestore)();
    const uid = request.auth.uid;
    const bunnyVideoId = String(request.data?.bunnyVideoId ?? "");
    const pending = await db.collection("pending_uploads").doc(bunnyVideoId).get();
    if (!pending.exists || pending.get("uid") !== uid) {
        throw new https_1.HttpsError("permission-denied", "That upload is not yours");
    }
    const linkedProductId = request.data?.linkedProductId ?? null;
    // Only your own product can be linked — otherwise anyone could attach a
    // Buy Now button pointing at someone else's listing.
    //
    // Hoisted out of the branch because the price is read from it below: the
    // Reel carries a denormalised price so the feed can render a Buy Now figure
    // without a read per card.
    let product = null;
    if (linkedProductId) {
        product = await db.collection("products").doc(linkedProductId).get();
        if (!product.exists || product.get("seller_id") !== uid) {
            throw new https_1.HttpsError("permission-denied", "You can only link a product you are selling");
        }
    }
    const user = await db.collection("users").doc(uid).get();
    const reelRef = db.collection("reels").doc();
    await reelRef.set({
        author_id: uid,
        author_name: user.get("display_name") ?? "",
        author_avatar_url: user.get("photo_url") ?? null,
        bunny_video_id: bunnyVideoId,
        thumbnail_url: `https://vz-${bunnyVideoId}.b-cdn.net/thumbnail.jpg`,
        caption: String(request.data?.caption ?? "").slice(0, 300),
        // Lowercased copy powering the prefix search in §4. Written here rather
        // than queried case-insensitively because Firestore has no such operator.
        caption_lower: String(request.data?.caption ?? "")
            .slice(0, 300)
            .toLowerCase(),
        duration_seconds: Number(pending.get("duration_seconds")),
        linked_product_id: linkedProductId,
        // Stamped at publish so the button has a price from the first render. Kept
        // current afterwards by the trigger in products/unlinkProduct.ts.
        linked_product_price_minor: product
            ? product.get("price_minor")
            : null,
        linked_product_currency: product
            ? product.get("currency")
            : null,
        status: "published",
        likes_count: 0,
        views_count: 0,
        comments_count: 0,
        rank_score: 0,
        created_at: firestore_1.FieldValue.serverTimestamp(),
    });
    await pending.ref.delete();
    return { reelId: reelRef.id };
});
//# sourceMappingURL=uploadSlot.js.map