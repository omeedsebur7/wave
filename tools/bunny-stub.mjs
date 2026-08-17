#!/usr/bin/env node
/**
 * A local stand-in for the Bunny Stream REST API, for integration tests.
 *
 * Zero dependencies — node:http only — so it starts as fast as the emulator
 * and cannot drift with npm.
 *
 * WHY THIS EXISTS
 * ---------------
 * createBunnyUploadSlot calls video.bunnycdn.com from the Functions runtime.
 * FakeBunny was a Dart object in the test process. Nothing connected them, so
 * `expect(bunny.videoCount, 0)` passed because the fake was never touched — it
 * would have passed identically had the function created ten real billed
 * videos. The assertion could not fail, which is the same as not existing.
 *
 * Point BUNNY_API_BASE at this and the function's real HTTP calls land here,
 * where they can be counted.
 *
 * WHAT IT DELIBERATELY PRESERVES
 * ------------------------------
 * Encoding is ASYNCHRONOUS. A stub reporting status 4 immediately would let a
 * broken implementation pass, because the bug being guarded is publishing a
 * Reel before its rendition ladder exists. Status stays at 2 until
 * ENCODE_MS has elapsed since the upload PUT.
 *
 * It also REQUIRES the AccessKey header on every API route. A function that
 * forgot to send the key would work against a permissive stub and fail in
 * production; here it gets a 401.
 *
 * TWO CONSUMERS, TWO ADDRESSES, ONE STUB
 * --------------------------------------
 * This binds to 0.0.0.0, not 127.0.0.1, and that is load-bearing:
 *
 *   - The FUNCTIONS RUNTIME is a Node process on the host, so it reaches the
 *     stub on 127.0.0.1. That is what BUNNY_API_BASE should say.
 *   - The TEST is Dart code running inside the Android emulator, which reaches
 *     the host on 10.0.2.2 — arriving on the host's normal network interface,
 *     NOT loopback. A server bound only to 127.0.0.1 refuses it with
 *     ECONNREFUSED, which is the same reason `firebase emulators` needs
 *     --host 0.0.0.0.
 *
 * Binding 127.0.0.1 broke every test in publish_flow_test with
 * "Connection refused ... address = 10.0.2.2, port = 9999" before the first
 * assertion ran. Do not narrow it back without checking the emulator path.
 *
 * USAGE
 * -----
 *   node tools/bunny-stub.mjs                      # 0.0.0.0:9999, 200ms encode
 *   $env:ENCODE_MS=1500; node tools/bunny-stub.mjs # match the test's encodeMs
 *   PORT=9100 HOST=127.0.0.1 node tools/bunny-stub.mjs
 *
 * Then in functions/.env.local — loopback, because the Functions runtime is a
 * host process:
 *   BUNNY_API_BASE=http://127.0.0.1:9999
 *
 * and in functions/.secret.local (values are never checked, only presence):
 *   BUNNY_API_KEY=stub-key
 *   BUNNY_LIBRARY_ID=stub-library
 *
 * The Dart side defaults to 10.0.2.2 and is overridable with
 * --dart-define=BUNNY_STUB_URL=http://<host-lan-ip>:9999 for a physical device.
 *
 * If the emulator still cannot reach it, Windows Firewall is blocking inbound
 * on the port:
 *   New-NetFirewallRule -DisplayName "Bunny stub 9999" -Direction Inbound `
 *     -LocalPort 9999 -Protocol TCP -Action Allow
 *
 * API ROUTES (mirroring Bunny)
 *   POST   /library/:lib/videos          -> { guid }
 *   PUT    /library/:lib/videos/:guid    -> starts the encode clock
 *   GET    /library/:lib/videos/:guid    -> { guid, status }
 *   DELETE /library/:lib/videos/:guid    -> removes it
 *
 * CONTROL ROUTES (for tests; no AccessKey required)
 *   POST /__control/reset
 *   GET  /__control/videos               -> { count, videos: [...] }
 *   POST /__control/fail-next-create     -> next POST returns 500
 *   POST /__control/fail-next-encode     -> next uploaded video ends at 5
 *   POST /__control/reject-delete        -> DELETE returns 500 until reset
 *   GET  /__control/health               -> { ok: true } — reachability check
 */

import { createServer } from "node:http";
import { randomUUID } from "node:crypto";
import { networkInterfaces } from "node:os";

const PORT = Number(process.env.PORT ?? 9999);
const ENCODE_MS = Number(process.env.ENCODE_MS ?? 200);

/**
 * All interfaces by default. See "TWO CONSUMERS" above — the Android emulator
 * cannot reach a loopback-only socket.
 */
const HOST = process.env.HOST ?? "0.0.0.0";

/** guid -> { uploadedAt: number|null, willFail: boolean, title: string } */
const videos = new Map();

let failNextCreate = false;
let failNextEncode = false;
let rejectDelete = false;

/**
 * Bunny's documented status codes. Only 4 and 5 are load-bearing —
 * bunnyVideoStatus maps 4 to ready and 5 to failed — but the intermediate
 * values are returned truthfully so a client polling for "not yet" sees
 * something realistic rather than a value that only ever means "no".
 */
const STATUS = { CREATED: 0, ENCODING: 2, FINISHED: 4, FAILED: 5 };

function statusOf(video) {
  if (video.uploadedAt === null) return STATUS.CREATED;
  if (video.willFail) return STATUS.FAILED;
  const elapsed = Date.now() - video.uploadedAt;
  return elapsed >= ENCODE_MS ? STATUS.FINISHED : STATUS.ENCODING;
}

function json(res, code, body) {
  const payload = JSON.stringify(body);
  res.writeHead(code, {
    "Content-Type": "application/json",
    "Content-Length": Buffer.byteLength(payload),
  });
  res.end(payload);
}

function drain(req) {
  return new Promise((resolve) => {
    let n = 0;
    req.on("data", (chunk) => { n += chunk.length; });
    req.on("end", () => resolve(n));
  });
}

const server = createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);
  const path = url.pathname;
  const method = req.method ?? "GET";

  // ── Control plane ───────────────────────────────────────────────────────
  if (path.startsWith("/__control")) {
    await drain(req);

    // Cheap reachability probe. Answers the only question worth asking when a
    // test dies before its first assertion: can the caller see this at all?
    if (path === "/__control/health") {
      return json(res, 200, { ok: true, port: PORT, encodeMs: ENCODE_MS });
    }
    if (path === "/__control/reset" && method === "POST") {
      videos.clear();
      failNextCreate = false;
      failNextEncode = false;
      rejectDelete = false;
      return json(res, 200, { ok: true });
    }
    if (path === "/__control/videos" && method === "GET") {
      return json(res, 200, {
        count: videos.size,
        videos: [...videos.entries()].map(([guid, v]) => ({
          guid,
          title: v.title,
          status: statusOf(v),
          uploaded: v.uploadedAt !== null,
        })),
      });
    }
    if (path === "/__control/fail-next-create" && method === "POST") {
      failNextCreate = true;
      return json(res, 200, { ok: true });
    }
    if (path === "/__control/fail-next-encode" && method === "POST") {
      failNextEncode = true;
      return json(res, 200, { ok: true });
    }
    if (path === "/__control/reject-delete" && method === "POST") {
      rejectDelete = true;
      return json(res, 200, { ok: true });
    }
    return json(res, 404, { error: `No control route ${method} ${path}` });
  }

  // ── AccessKey, on every API route ───────────────────────────────────────
  // Presence only; the value is never checked. The point is to fail a function
  // that forgot to send it, which would otherwise pass locally and 401 in
  // production.
  const accessKey = req.headers["accesskey"];
  if (!accessKey || String(accessKey).length === 0) {
    await drain(req);
    return json(res, 401, {
      error:
        "Missing AccessKey header. The real Bunny API rejects this; the stub " +
        "does too, so the omission cannot pass locally.",
    });
  }

  // /library/:lib/videos[/:guid]
  const parts = path.split("/").filter(Boolean);
  if (parts[0] !== "library" || parts[2] !== "videos") {
    await drain(req);
    return json(res, 404, { error: `Unrecognised path ${path}` });
  }
  const guid = parts[3];

  // ── POST /library/:lib/videos — create ──────────────────────────────────
  if (!guid && method === "POST") {
    let body = "";
    req.on("data", (c) => { body += c; });
    await new Promise((r) => req.on("end", r));

    if (failNextCreate) {
      failNextCreate = false;
      // 500, matching what the function's `!created.ok` branch handles. Lets a
      // test assert the create failure surfaces as a clean error AND that no
      // pending_uploads document is left behind.
      return json(res, 500, { error: "Injected create failure" });
    }

    let title = "Reel";
    try {
      title = String(JSON.parse(body || "{}").title ?? "Reel");
    } catch {
      return json(res, 400, { error: "Body was not valid JSON" });
    }

    const newGuid = randomUUID();
    videos.set(newGuid, { uploadedAt: null, willFail: false, title });
    return json(res, 200, { guid: newGuid, title });
  }

  if (!guid) {
    await drain(req);
    return json(res, 405, { error: `${method} not allowed on the collection` });
  }

  const video = videos.get(guid);
  if (!video) {
    await drain(req);
    return json(res, 404, { error: `No video ${guid}` });
  }

  // ── PUT — the direct byte upload; starts the encode clock ───────────────
  if (method === "PUT") {
    const bytes = await drain(req);
    video.uploadedAt = Date.now();
    video.willFail = failNextEncode;
    failNextEncode = false;
    return json(res, 200, { success: true, bytesReceived: bytes });
  }

  // ── GET — status ────────────────────────────────────────────────────────
  if (method === "GET") {
    await drain(req);
    return json(res, 200, { guid, title: video.title, status: statusOf(video) });
  }

  // ── DELETE — the compensating delete ───────────────────────────────────
  if (method === "DELETE") {
    await drain(req);
    if (rejectDelete) {
      // Leaves the video in place, which is the honest simulation: a failed
      // delete means the orphan is still there. This is the path that only
      // logs, and it was previously unreachable in any test.
      return json(res, 500, { error: "Injected delete failure" });
    }
    videos.delete(guid);
    return json(res, 200, { success: true });
  }

  await drain(req);
  return json(res, 405, { error: `${method} not allowed on a video` });
});

server.on("error", (error) => {
  if (error.code === "EADDRINUSE") {
    console.error(
      `Port ${PORT} is already in use — an older stub is probably still ` +
        `running. Stop it, or start this one with PORT=<other>.`
    );
    process.exit(1);
  }
  throw error;
});

server.listen(PORT, HOST, () => {
  console.log(`Bunny stub listening on ${HOST}:${PORT}  (encode ${ENCODE_MS}ms)`);
  console.log("");
  console.log(`  Functions runtime (host process, use loopback):`);
  console.log(`    functions/.env.local -> BUNNY_API_BASE=http://127.0.0.1:${PORT}`);
  console.log("");
  console.log(`  Dart test inside the Android emulator:`);
  console.log(`    http://10.0.2.2:${PORT}   (FakeBunny's default)`);

  if (HOST === "0.0.0.0") {
    const lan = Object.values(networkInterfaces())
      .flat()
      .filter((i) => i && i.family === "IPv4" && !i.internal)
      .map((i) => i.address);
    if (lan.length > 0) {
      console.log("");
      console.log(`  Physical device on the same network:`);
      for (const address of lan) {
        console.log(`    --dart-define=BUNNY_STUB_URL=http://${address}:${PORT}`);
      }
    }
  } else {
    console.log("");
    console.log(
      `  WARNING: bound to ${HOST}. The Android emulator reaches the host on ` +
        `10.0.2.2, which does NOT arrive on loopback — tests will fail with ` +
        `ECONNREFUSED. Unset HOST to bind 0.0.0.0.`
    );
  }

  console.log("");
  console.log(`  Reachability check: curl http://127.0.0.1:${PORT}/__control/health`);
});

for (const signal of ["SIGINT", "SIGTERM"]) {
  process.on(signal, () => {
    server.close(() => process.exit(0));
  });
}
