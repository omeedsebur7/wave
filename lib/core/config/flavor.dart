/// Build flavors (§6 — Environment Flavors). Each maps to its own Firebase
/// project, so staging traffic can never write to production Firestore.
enum Flavor {
  dev('dev', 'WAVE Dev'),
  staging('staging', 'WAVE Staging'),
  prod('prod', 'WAVE');

  const Flavor(this.id, this.appName);
  final String id;
  final String appName;

  bool get isProd => this == Flavor.prod;
}

abstract final class AppConfig {
  static late Flavor flavor;

  /// Bunny Stream library/pull-zone hostname. The signing SECRET never ships
  /// in the client — a Cloud Function signs playback URLs (§6, Security).
  static late String bunnyPullZoneHost;

  static bool get isProd => flavor.isProd;
}
