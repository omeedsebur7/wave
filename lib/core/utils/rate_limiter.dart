import 'dart:collection';

/// Client-side throttle for comments, reviews, chat and OTP sends (§4, §1).
///
/// This is a UX guard, not a security control — it stops accidental spam and
/// gives instant feedback without a round-trip. The real enforcement lives in
/// Firestore Security Rules and the Cloud Functions layer, because anything
/// running on the client can be removed by someone determined enough.
class RateLimiter {
  RateLimiter({required this.maxEvents, required this.window});

  final int maxEvents;
  final Duration window;
  final _events = HashMap<String, Queue<DateTime>>();

  /// Returns null if allowed, or the time left to wait if throttled.
  Duration? check(String bucket, {DateTime? now}) {
    final t = now ?? DateTime.now();
    final q = _events.putIfAbsent(bucket, Queue<DateTime>.new);
    while (q.isNotEmpty && t.difference(q.first) > window) {
      q.removeFirst();
    }
    if (q.length >= maxEvents) {
      return window - t.difference(q.first);
    }
    q.add(t);
    return null;
  }

  void reset(String bucket) => _events.remove(bucket);
}
