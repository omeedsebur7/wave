import 'dart:convert';

import 'package:http/http.dart' as http;

/// A client for the local Bunny stub (tools/bunny-stub.mjs).
///
/// This used to be an in-process fake, and that was the bug. It held its own
/// Map of videos while `createBunnyUploadSlot` called video.bunnycdn.com from
/// the Functions runtime — two unconnected systems. So
/// `expect(bunny.videoCount, 0)`, written to prove no Bunny video is created
/// for a rejected duration, passed because nothing had touched the fake. It
/// would have passed identically had the function created ten real billed
/// videos. The assertion could not fail, which is the same as not being there.
///
/// Now every method here talks to the same stub the function does, so the
/// counts and statuses describe what the function actually did.
///
/// What the stub preserves, and why it matters: encoding is ASYNCHRONOUS.
/// A stub reporting "ready" immediately would let a broken implementation pass,
/// because the bug being guarded against is publishing a Reel before its
/// rendition ladder exists.
class FakeBunny {
  FakeBunny({
    String? baseUrl,
    this.encodeDuration = const Duration(milliseconds: 200),
  }) : baseUrl = baseUrl ??
            const String.fromEnvironment(
              'BUNNY_STUB_URL',
              // The Android emulator reaches the host machine on 10.0.2.2, the
              // same reason EMULATOR_HOST exists. Overridable via
              // --dart-define=BUNNY_STUB_URL=... for a physical device.
              defaultValue: 'http://10.0.2.2:9999',
            );

  /// Where the stub is listening. Must match BUNNY_API_BASE in
  /// functions/.env.local, or the function and the test will be looking at two
  /// different stubs — which is the failure this class was rewritten to end.
  final String baseUrl;

  /// How long the stub takes to "transcode". Must match ENCODE_MS on the stub
  /// process; a test that waits less than the stub takes will see `ready:
  /// false` and read it as a broken implementation.
  final Duration encodeDuration;

  Future<Map<String, dynamic>> _control(
    String route, {
    String method = 'POST',
  }) async {
    final uri = Uri.parse('$baseUrl/__control/$route');
    final response = method == 'GET'
        ? await http.get(uri)
        : await http.post(uri);

    if (response.statusCode >= 300) {
      throw StateError(
        'Bunny stub control call "$route" failed: '
        '${response.statusCode} ${response.body}. Is the stub running? '
        '`node tools/bunny-stub.mjs`',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Uploads bytes to a slot, which starts the encode clock.
  ///
  /// Takes the videoId returned by the REAL callable — `seed.requestUploadSlot`
  /// — not a locally invented one. An id this class made up has no
  /// `pending_uploads` document behind it, so `publishReel` correctly refuses
  /// it with "That upload is not yours".
  Future<void> upload(String videoId, {String library = 'stub-library'}) async {
    final response = await http.put(
      Uri.parse('$baseUrl/library/$library/videos/$videoId'),
      headers: const {'AccessKey': 'stub-key'},
      body: 'fake video bytes',
    );

    if (response.statusCode >= 300) {
      throw StateError(
        'Stub upload failed for $videoId: '
        '${response.statusCode} ${response.body}',
      );
    }
  }

  /// Mirrors `bunnyVideoStatus`, read from the stub rather than guessed at.
  Future<({bool ready, bool failed})> status(
    String videoId, {
    String library = 'stub-library',
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/library/$library/videos/$videoId'),
      headers: const {'AccessKey': 'stub-key'},
    );

    if (response.statusCode == 404) return (ready: false, failed: true);
    if (response.statusCode >= 300) {
      throw StateError(
        'Stub status failed for $videoId: '
        '${response.statusCode} ${response.body}',
      );
    }

    final code = (jsonDecode(response.body) as Map<String, dynamic>)['status'];
    return (ready: code == 4, failed: code == 5);
  }

  /// How many video objects the FUNCTION has created.
  ///
  /// The assertion this class exists for. A test expecting one upload and
  /// finding three has found a retry loop; a test expecting zero and finding
  /// one has found a validation check running after the Bunny call instead of
  /// before it.
  Future<int> videoCount() async {
    final body = await _control('videos', method: 'GET');
    return body['count'] as int;
  }

  Future<List<Map<String, dynamic>>> videos() async {
    final body = await _control('videos', method: 'GET');
    return (body['videos'] as List).cast<Map<String, dynamic>>();
  }

  /// The next created video will finish encoding as FAILED.
  ///
  /// Different from a failed upload: the bytes arrived and the video is
  /// unusable, so no Reel document may be written.
  Future<void> failNextEncode() => _control('fail-next-encode');

  /// The next create call returns 500, exercising the `!created.ok` branch.
  Future<void> failNextCreate() => _control('fail-next-create');

  /// DELETE returns 500 until reset, exercising the compensating-delete path
  /// in createBunnyUploadSlot that only logs — previously unreachable.
  Future<void> rejectDelete() => _control('reject-delete');

  Future<void> reset() => _control('reset');
}