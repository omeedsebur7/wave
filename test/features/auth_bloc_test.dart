import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wave/core/analytics/analytics_service.dart';
import 'package:wave/core/error/failures.dart';
import 'package:wave/core/utils/result.dart';
import 'package:wave/features/auth/domain/entities/wave_user.dart';
import 'package:wave/features/auth/domain/repositories/auth_repository.dart';
import 'package:wave/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:wave/features/notifications/data/repositories/notification_repository.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockAnalytics extends Mock implements AnalyticsService {}

class _MockNotifications extends Mock implements NotificationRepository {}

const _guest = WaveUser(uid: 'g1', isGuest: true, phoneVerified: false);
const _unverified = WaveUser(uid: 'u1', isGuest: false, phoneVerified: false);
const _verified = WaveUser(uid: 'u1', isGuest: false, phoneVerified: true);

void main() {
  late _MockAuthRepository repo;
  late _MockAnalytics analytics;
  late _MockNotifications notifications;

  setUp(() {
    repo = _MockAuthRepository();
    analytics = _MockAnalytics();
    notifications = _MockNotifications();
    when(() => analytics.setUser(any())).thenAnswer((_) async {});
    when(() => analytics.log(any(), params: any(named: 'params')))
        .thenAnswer((_) async {});
    // Stubbed although nothing below signs out, because the failure mode if it
    // is missing is misleading: mocktail throws on the unstubbed call from
    // inside the handler, and the test reports a null-ish state rather than
    // naming the unregistered token.
    when(() => notifications.unregisterDeviceToken()).thenAnswer((_) async {});
  });

  /// One construction site for the bloc.
  ///
  /// Previously each test called the constructor inline, so adding
  /// NotificationRepository broke seven of them at once. The next dependency
  /// costs one edit.
  ///
  /// The `when(...)` stub for `repo.authState` stays in each test's `build:` —
  /// it differs per test and must be registered before the bloc subscribes, so
  /// it cannot move in here.
  AuthBloc buildBloc() => AuthBloc(repo, analytics, notifications);

  group('AuthBloc status mapping', () {
    blocTest<AuthBloc, AuthState>(
      'a null user means signed out',
      build: () {
        when(() => repo.authState).thenAnswer((_) => Stream.value(null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const AuthStarted()),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) => expect(bloc.state.status, AuthStatus.signedOut),
    );

    blocTest<AuthBloc, AuthState>(
      'an anonymous user is a guest, not signed in',
      build: () {
        when(() => repo.authState).thenAnswer((_) => Stream.value(_guest));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const AuthStarted()),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.status, AuthStatus.guest);
        expect(bloc.state.isGuest, isTrue);
        expect(bloc.state.canCheckout, isFalse);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'a signed-in user without a verified phone cannot check out yet',
      build: () {
        when(() => repo.authState).thenAnswer((_) => Stream.value(_unverified));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const AuthStarted()),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.status, AuthStatus.signedIn);
        expect(bloc.state.needsPhoneVerification, isTrue);
        expect(bloc.state.canCheckout, isFalse);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'a verified user can check out',
      build: () {
        when(() => repo.authState).thenAnswer((_) => Stream.value(_verified));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const AuthStarted()),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) => expect(bloc.state.canCheckout, isTrue),
    );

    blocTest<AuthBloc, AuthState>(
      'status starts unknown, so routing never flashes the sign-in screen',
      // The enum's own doc calls this out: routing must wait rather than guess,
      // or a signed-in user is shown the sign-in screen on every cold start.
      // Nothing asserted that the initial state actually IS unknown — the four
      // tests above all wait for the stream to deliver, which is precisely the
      // window this guards.
      build: () {
        when(() => repo.authState).thenAnswer((_) => const Stream.empty());
        return buildBloc();
      },
      verify: (bloc) {
        expect(bloc.state.status, AuthStatus.unknown);
        expect(bloc.state.canCheckout, isFalse);
      },
    );
  });

  group('OTP flow', () {
    blocTest<AuthBloc, AuthState>(
      'a successful send moves to awaitingCode and stores the verificationId',
      build: () {
        when(() => repo.authState).thenAnswer((_) => const Stream.empty());
        when(() => repo.sendOtp(any()))
            .thenAnswer((_) async => const Success('vid-123'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const OtpRequested('+9647700000000')),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.otpStage, OtpStage.awaitingCode);
        expect(bloc.state.verificationId, 'vid-123');
      },
    );

    blocTest<AuthBloc, AuthState>(
      'a wrong code returns to awaitingCode, not idle',
      // Sending them back to the phone field would burn another SMS for a
      // typo. They stay on the code field with the error.
      build: () {
        when(() => repo.authState).thenAnswer((_) => const Stream.empty());
        when(() => repo.sendOtp(any()))
            .thenAnswer((_) async => const Success('vid-123'));
        when(
          () => repo.linkPhoneToCurrentUser(
            verificationId: any(named: 'verificationId'),
            smsCode: any(named: 'smsCode'),
          ),
        ).thenAnswer(
          (_) async => const Err(AuthFailure('That code is not right')),
        );
        return buildBloc();
      },
      // The 20ms sleep is the most fragile line in this file: it assumes
      // sendOtp resolves inside 20ms of wall-clock time. On a loaded CI runner
      // it may not, and the test then fails claiming the OTP stage is wrong
      // when the real cause is scheduling. If it flakes, await the state
      // instead of sleeping for it —
      //   await bloc.stream.firstWhere(
      //     (s) => s.otpStage == OtpStage.awaitingCode);
      // — which is both faster and deterministic.
      act: (bloc) async {
        bloc.add(const OtpRequested('+9647700000000'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(const OtpSubmitted('000000', linkToExisting: true));
      },
      wait: const Duration(milliseconds: 80),
      verify: (bloc) {
        expect(bloc.state.otpStage, OtpStage.awaitingCode);
        expect(bloc.state.failure, isNotNull);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'submitting without requesting a code first fails cleanly',
      build: () {
        when(() => repo.authState).thenAnswer((_) => const Stream.empty());
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const OtpSubmitted('123456', linkToExisting: false)),
      wait: const Duration(milliseconds: 30),
      verify: (bloc) {
        expect(bloc.state.failure, isA<AuthFailure>());
        // Asserting the reason, not just the type. The handler sets
        // FailureReason.requestCodeFirst specifically so the UI can send them
        // back to the phone field rather than showing a generic error on a
        // code field they cannot fix. isA<AuthFailure>() alone passes for any
        // auth error at all, including ones that should not send them back.
        expect(
          (bloc.state.failure! as AuthFailure).reason,
          FailureReason.requestCodeFirst,
        );
      },
    );
  });
}