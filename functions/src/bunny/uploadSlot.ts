import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { DocumentSnapshot, FieldValue, getFirestore, Timestamp } from "firebase-admin/firestore";

const BUNNY_API_KEY = defineSecret("BUNNY_API_KEY");
const BUNNY_LIBRARY_ID = defineSecret("BUNNY_LIBRARY_ID");

/**
 * Base URL for the Bunny Stream REST API.
 *
 * Overridable ONLY so integration tests can point it at a local stub. See
 * tools/bunny-stub.mjs and integration_test/publish_flow_test.dart.
 */
const BUNNY_API_BASE =
  process.env.BUNNY_API_BASE ?? "https://video.bunnycdn.com";

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
 */
export const createBunnyUploadSlot = onCall(
  { secrets: [BUNNY_API_KEY, BUNNY_LIBRARY_ID], cors: true },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in to publish");
    }
    if (request.auth.token.firebase?.sign_in_provider === "anonymous") {
      throw new HttpsError("permission-denied", "Guests cannot publish");
    }

    const uid = request.auth.uid;
    const durationSeconds = Number(request.data?.durationSeconds ?? 0);

    // Server-side duration cap. The client checks too, but only this check
    // counts — a modified client could send anything.
    if (durationSeconds <= 0 || durationSeconds > 60) {
      throw new HttpsError("invalid-argument", "Reels must be 60 seconds or less");
    }

    // Publish rate limit. Without this, one script can fill a video library.
    const db = getFirestore();
    const since = Timestamp.fromMillis(
      Date.now() - 60 * 60 * 1000
    );
    const recent = await db
      .collection("reels")
      .where("author_id", "==", uid)
      .where("created_at", ">", since)
      .count()
      .get();

    if (recent.data().count >= 10) {
      throw new HttpsError(
        "resource-exhausted",
        "You have posted a lot in the last hour. Try again later."
      );
    }

    const libraryId = BUNNY_LIBRARY_ID.value();
    const created = await fetch(
      `${BUNNY_API_BASE}/library/${libraryId}/videos`,
      {
        method: "POST",
        headers: {
          AccessKey: BUNNY_API_KEY.value(),
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ title: String(request.data?.title ?? "Reel") }),
      }
    );

    if (!created.ok) {
      throw new HttpsError(
        "internal",
        `Could not create the video (Bunny returned ${created.status})`
      );
    }

    const video = (await created.json()) as { guid: string };

    // Claim the video against this user before returning it, so publishReel
    // can verify ownership later and nobody can publish someone else's upload.
    try {
      await db.collection("pending_uploads").doc(video.guid).set({
        uid,
        duration_seconds: durationSeconds,
        created_at: FieldValue.serverTimestamp(),
      });
    } catch (writeError) {
      try {
        const deleted = await fetch(
          `${BUNNY_API_BASE}/library/${libraryId}/videos/${video.guid}`,
          { method: "DELETE", headers: { AccessKey: BUNNY_API_KEY.value() } }
        );
        if (!deleted.ok) {
          throw new Error(`Bunny returned ${deleted.status}`);
        }
      } catch (cleanupError) {
        console.error(
          `Orphaned Bunny video ${video.guid} in library ${libraryId}: ` +
            `ownership record failed to write (${writeError}) and the ` +
            `compensating delete also failed (${cleanupError}). ` +
            `Remove it manually via the Bunny dashboard.`
        );
      }

      throw new HttpsError(
        "internal",
        "Could not finish setting up the upload. Please try again."
      );
    }

    return {
      videoId: video.guid,
      uploadUrl: `${BUNNY_API_BASE}/library/${libraryId}/videos/${video.guid}`,
    };
  }
);

/**
 * Bunny Stream status codes. Only 4 and 5 are load-bearing anywhere in this
 * file — 4 means the rendition ladder actually exists and is playable, 5
 * means the encode failed outright — but the others are named here rather
 * than left as bare integers, since a future reader comparing against a raw
 * `4` has no way to know it means "finished" without checking Bunny's own
 * docs.
 */
const BUNNY_STATUS_FINISHED = 4;

/** Polled by the client while Bunny transcodes. */
export const bunnyVideoStatus = onCall(
  { secrets: [BUNNY_API_KEY, BUNNY_LIBRARY_ID], cors: true },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in first");
    }

    const videoId = String(request.data?.videoId ?? "");
    if (!/^[a-zA-Z0-9-]+$/.test(videoId)) {
      throw new HttpsError("invalid-argument", "Invalid videoId");
    }

    const res = await fetch(
      `${BUNNY_API_BASE}/library/${BUNNY_LIBRARY_ID.value()}/videos/${videoId}`,
      { headers: { AccessKey: BUNNY_API_KEY.value() } }
    );

    if (!res.ok) throw new HttpsError("internal", "Could not read video status");

    // Bunny status codes: 4 = finished, 5 = failed.
    const video = (await res.json()) as { status: number };
    return { ready: video.status === 4, failed: video.status === 5 };
  }
);

/**
 * Writes the Reel document once the video is genuinely playable.
 *
 * Separate from the upload slot deliberately: a Reel that exists before its
 * rendition ladder does is a Reel the feed will show and fail to play, which
 * is a worse experience than a slightly delayed post.
 *
 * THE FIX BELOW: this function used to verify only the pending_uploads
 * ownership record and nothing else. Its own doc comment claimed it "writes
 * the Reel document once the video is genuinely playable" — but that
 * guarantee lived entirely in the CLIENT, which polls bunnyVideoStatus and
 * only calls this once ready. A client bug, a race between the poll and the
 * call, or a modified client bypassed it completely: calling this with a
 * videoId whose encode had FAILED still wrote a Reel, because nothing here
 * ever asked Bunny.
 *
 * Found by integration_test/publish_flow_test.dart's "a failed encode is
 * reported as failed, not as ready" test, which could only assert on the
 * STATUS ENDPOINT reporting failure correctly — the actual gap, publishReel
 * accepting a failed video anyway, was left as a comment with the exact
 * replacement assertion, because a failing test nobody could fix from that
 * file alone just gets skipped. That replacement assertion is now real: see
 * the test file for the `throwsA(failed-precondition)` case this unlocks.
 *
 * The secrets are now required here for the same reason they are on
 * bunnyVideoStatus — this function talks to Bunny directly rather than
 * trusting anything the client claims about encode status.
 */
export const publishReel = onCall(
  { secrets: [BUNNY_API_KEY, BUNNY_LIBRARY_ID], cors: true },
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Sign in first");

    const db = getFirestore();
    const uid = request.auth.uid;
    const bunnyVideoId = String(request.data?.bunnyVideoId ?? "");

    const pending = await db.collection("pending_uploads").doc(bunnyVideoId).get();
    if (!pending.exists || pending.get("uid") !== uid) {
      throw new HttpsError("permission-denied", "That upload is not yours");
    }

    // The encode-status check.
    //
    // Ordered AFTER the ownership check and BEFORE any other read, so a
    // caller who does not own this upload gets "not yours" rather than a
    // status-shaped error that would leak whether a video id they guessed at
    // exists at all. Ordered BEFORE the product-link check below for the
    // opposite reason: there is no point validating a product link on a Reel
    // that is never going to be writable anyway.
    const statusRes = await fetch(
      `${BUNNY_API_BASE}/library/${BUNNY_LIBRARY_ID.value()}/videos/${bunnyVideoId}`,
      { headers: { AccessKey: BUNNY_API_KEY.value() } }
    );

    if (!statusRes.ok) {
      // Bunny itself is unreachable or erroring. Distinguished from "encode
      // failed" deliberately: a transient Bunny outage is not evidence the
      // video is bad, and telling the caller "encode failed" here would send
      // them to re-upload something that was probably fine.
      throw new HttpsError(
        "internal",
        `Could not confirm the video is playable (Bunny returned ${statusRes.status})`
      );
    }

    const video = (await statusRes.json()) as { status: number };
    if (video.status !== BUNNY_STATUS_FINISHED) {
      // failed-precondition, matching the payment-gate and self-dealing
      // pattern elsewhere in this codebase: the request was well-formed, the
      // caller is who they say they are, but the STATE the world is in does
      // not permit this action yet. A retry once encoding actually finishes
      // is the correct next step, which is what this code tells the client.
      throw new HttpsError(
        "failed-precondition",
        "This video is not ready to publish yet. Wait for it to finish encoding."
      );
    }

    const linkedProductId = request.data?.linkedProductId ?? null;

    // Only your own product can be linked — otherwise anyone could attach a
    // Buy Now button pointing at someone else's listing.
    //
    // Hoisted out of the branch because the price is read from it below: the
    // Reel carries a denormalised price so the feed can render a Buy Now
    // figure without a read per card.
    let product: DocumentSnapshot | null = null;

    if (linkedProductId) {
      product = await db.collection("products").doc(linkedProductId).get();
      if (!product.exists || product.get("seller_id") !== uid) {
        throw new HttpsError(
          "permission-denied",
          "You can only link a product you are selling"
        );
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
        ? (product.get("price_minor") as number)
        : null,
      linked_product_currency: product
        ? (product.get("currency") as string)
        : null,
      status: "published",
      likes_count: 0,
      views_count: 0,
      comments_count: 0,
      rank_score: 0,
      created_at: FieldValue.serverTimestamp(),
    });

    await pending.ref.delete();

    return { reelId: reelRef.id };
  }
);
