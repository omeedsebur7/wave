class ServerException implements Exception {
  ServerException(this.message, {this.code});
  final String message;
  final String? code;
}

// CacheException and RateLimitException were removed: nothing threw them.
// Both concerns are expressed as Failures in the domain layer instead, and an
// unused exception class is an invitation to introduce a second error channel
// alongside the one that already works.
