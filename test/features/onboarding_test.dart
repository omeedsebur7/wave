import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wave/features/onboarding/data/onboarding_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OnboardingService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = OnboardingService(await SharedPreferences.getInstance());
  });

  group('Onboarding state', () {
    test('a fresh install has not seen the walkthrough', () {
      expect(service.hasSeenOnboarding, isFalse);
    });

    test('markSeen persists', () async {
      await service.markSeen();
      expect(service.hasSeenOnboarding, isTrue);
    });

    test('reset brings the walkthrough back', () async {
      await service.markSeen();
      await service.reset();
      expect(service.hasSeenOnboarding, isFalse);
    });
  });

  group('Permission priming', () {
    test('nothing is primed on a fresh install', () {
      for (final permission in PrimedPermission.values) {
        expect(service.hasPrimed(permission), isFalse);
      }
    });

    test('priming one permission does not prime the other', () async {
      // They are asked for at different moments — notifications after
      // onboarding, camera at first recording — so they must be tracked apart.
      await service.markPrimed(PrimedPermission.notifications);
      expect(service.hasPrimed(PrimedPermission.notifications), isTrue);
      expect(service.hasPrimed(PrimedPermission.camera), isFalse);
    });

    test('priming survives a new service instance', () async {
      await service.markPrimed(PrimedPermission.camera);
      final reloaded = OnboardingService(await SharedPreferences.getInstance());
      expect(reloaded.hasPrimed(PrimedPermission.camera), isTrue);
    });
  });
}
