import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the first-run walkthrough has been seen (§1).
///
/// Stored locally rather than on the user profile, deliberately: onboarding
/// runs BEFORE sign-in, so there is no profile to write to yet. It is also a
/// per-install concern — someone reinstalling on a new phone genuinely does
/// want the walkthrough again.
class OnboardingService {
  OnboardingService(this._prefs);

  final SharedPreferences _prefs;

  static const _seenKey = 'onboarding_seen_v1';
  static const _notificationsPrimedKey = 'notifications_primed';
  static const _cameraPrimedKey = 'camera_primed';

  bool get hasSeenOnboarding => _prefs.getBool(_seenKey) ?? false;

  Future<void> markSeen() => _prefs.setBool(_seenKey, true);

  /// Whether we have already shown the priming screen for a permission.
  ///
  /// This is NOT whether the permission was granted — the OS owns that. It is
  /// whether we have spent our one good chance at explaining why we are asking.
  bool hasPrimed(PrimedPermission permission) =>
      _prefs.getBool(_keyFor(permission)) ?? false;

  Future<void> markPrimed(PrimedPermission permission) =>
      _prefs.setBool(_keyFor(permission), true);

  static String _keyFor(PrimedPermission permission) => switch (permission) {
        PrimedPermission.notifications => _notificationsPrimedKey,
        PrimedPermission.camera => _cameraPrimedKey,
      };

  /// Reset hook for the "see the walkthrough again" affordance in settings, and
  /// for integration tests that need a clean first run.
  Future<void> reset() async {
    await _prefs.remove(_seenKey);
    await _prefs.remove(_notificationsPrimedKey);
    await _prefs.remove(_cameraPrimedKey);
  }
}

enum PrimedPermission { notifications, camera }
