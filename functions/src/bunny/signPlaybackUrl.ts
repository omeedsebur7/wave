import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as crypto from "crypto";

/**
 * Bunny Stream token authentication (§6 — Security).
 *
 * The signing key lives here and ONLY here. The same reasoning that keeps write
 * access off unauthenticated clients in Security Rules applies: a key shipped
 * inside an app binary is a public key, whatever the obfuscation around it.
 * With the key server-side, a leaked playback URL expires in minutes and can be
 * scoped to one IP; with the key on-device, a leaked key means unlimited free
 * bandwidth billed to you.
 */
const BUNNY_TOKEN_KEY = defineSecret("BUNNY_TOKEN_AUTH_KEY");
const BUNNY_PULL_ZONE = defineSecret("BUNNY_PULL_ZONE_HOST");

const URL_TTL_SECONDS = 60 * 30; // 30 min — long enough for a full watch, short
                                 // enough that a shared URL dies quickly.

export const signBunnyPlaybackUrl = onCall(
  { secrets: [BUNNY_TOKEN_KEY, BUNNY_PULL_ZONE], cors: true },
  async (request) => {
    // Guests may watch, so anonymous auth is fine here — but an unauthenticated
    // caller is not, or the CDN becomes an open proxy.
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in to watch Reels");
    }

    const videoId = request.data?.videoId;
    if (typeof videoId !== "string" || !/^[a-zA-Z0-9-]+$/.test(videoId)) {
      throw new HttpsError("invalid-argument", "Invalid videoId");
    }

    const key = BUNNY_TOKEN_KEY.value();
    const host = BUNNY_PULL_ZONE.value();

    // Data Saver (§6). Bunny serves a resolution-capped playlist when the
    // height is in the path, so the player never even sees the higher
    // renditions — capping client-side would still download the manifest and
    // let the player climb.
    const requested = Number(request.data?.maxHeight ?? 0);
    const allowed = [360, 480, 720];
    const cap = allowed.includes(requested) ? requested : null;

    const path = cap
      ? `/${videoId}/playlist.m3u8?resolutions=${allowed.filter((r) => r <= cap).join(",")}`
      : `/${videoId}/playlist.m3u8`;
    const expires = Math.floor(Date.now() / 1000) + URL_TTL_SECONDS;

    // Bunny's token auth: SHA256(key + path + expiry), base64url-encoded.
    const hash = crypto
      .createHash("sha256")
      .update(key + path + expires)
      .digest("base64")
      .replace(/\+/g, "-")
      .replace(/\//g, "_")
      .replace(/=/g, "");

    return {
      url: `https://${host}${path}?token=${hash}&expires=${expires}`,
      expiresAtMs: expires * 1000,
    };
  }
);
