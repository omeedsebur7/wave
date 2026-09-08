import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/core/analytics/analytics_events.dart';
import 'package:wave/core/analytics/analytics_service.dart';
import 'package:wave/core/error/failures.dart';
import 'package:wave/core/utils/result.dart';
import 'package:wave/features/auth/domain/entities/wave_user.dart';
import 'package:wave/features/auth/domain/repositories/auth_repository.dart';
import 'package:wave/features/location/data/saved_location_store.dart';
import 'package:wave/features/notifications/data/repositories/notification_repository.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class _AuthUserChanged extends AuthEvent {
  const _AuthUserChanged(this.user);
  final WaveUser? user;
  @override
  List<Object?> get props => [user];
}

class ConsentCaptured extends AuthEvent {
  const ConsentCaptured({
    required this.acceptedTerms,
    required this.confirmedAge,
    this.termsVersion = '1.0',
  });

  final bool acceptedTerms;
  final bool confirmedAge;
  final String termsVersion;

  @override
  List<Object?> get props => [acceptedTerms, confirmedAge, termsVersion];
}

class GoogleSignInRequested extends AuthEvent {
  const GoogleSignInRequested();
}

class AppleSignInRequested extends AuthEvent {
  const AppleSignInRequested();
}

class GuestSessionRequested extends AuthEvent {
  const GuestSessionRequested();
}

class OtpRequested extends AuthEvent {
  const OtpRequested(this.phoneNumber);
  final String phoneNumber;
  @override
  List<Object?> get props => [phoneNumber];
}

class OtpResetRequested extends AuthEvent {
  const OtpResetRequested();
}

class OtpSubmitted extends AuthEvent {
  const OtpSubmitted(this.smsCode, {required this.linkToExisting});
  final String smsCode;
  final bool linkToExisting;
  @override
  List<Object?> get props => [smsCode, linkToExisting];
}

class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}

enum AuthStatus {
  unknown,
  signedOut,
  guest,
  signedIn,
}

enum OtpStage { idle, sending, awaitingCode, verifying, verified }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.otpStage = OtpStage.idle,
    this.verificationId,
    this.isBusy = false,
    this.failure,
  });

  final AuthStatus status;
  final WaveUser? user;
  final OtpStage otpStage;
  final String? verificationId;
  final bool isBusy;
  final Failure? failure;

  bool get isSignedIn => status == AuthStatus.signedIn;
  bool get isGuest => status == AuthStatus.guest;
  bool get canCheckout => user?.canCheckout ?? false;
  bool get needsPhoneVerification => isSignedIn && !(user?.phoneVerified ?? false);

  AuthState copyWith({
    AuthStatus? status,
    WaveUser? user,
    OtpStage? otpStage,
    String? verificationId,
    bool? isBusy,
    Failure? failure,
    bool clearUser = false,
    bool clearFailure = false,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: clearUser ? null : (user ?? this.user),
        otpStage: otpStage ?? this.otpStage,
        verificationId: verificationId ?? this.verificationId,
        isBusy: isBusy ?? this.isBusy,
        failure: clearFailure ? null : (failure ?? this.failure),
      );

  @override
  List<Object?> get props =>
      [status, user, otpStage, verificationId, isBusy, failure];
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repo, this._analytics, this._notifications)
      : super(const AuthState()) {
    this
      ..on<AuthStarted>(_onStarted)
      ..on<ConsentCaptured>(
        (e, _) => _repo.captureConsent(
          acceptedTerms: e.acceptedTerms,
          confirmedAge: e.confirmedAge,
          termsVersion: e.termsVersion,
        ),
      )
      ..on<_AuthUserChanged>(_onUserChanged)
      ..on<GoogleSignInRequested>(_onGoogle)
      ..on<AppleSignInRequested>(_onApple)
      ..on<GuestSessionRequested>(_onGuest)
      ..on<OtpRequested>(_onOtpRequested)
      ..on<OtpResetRequested>(
        (_, emit) => emit(
          state.copyWith(otpStage: OtpStage.idle, clearFailure: true),
        ),
      )
      ..on<OtpSubmitted>(_onOtpSubmitted)
      ..on<SignOutRequested>(_onSignOut);
  }

  final AuthRepository _repo;
  final AnalyticsService _analytics;
  final NotificationRepository _notifications;
  StreamSubscription<WaveUser?>? _sub;

  Future<void> _onStarted(AuthStarted e, Emitter<AuthState> emit) async {
    await _sub?.cancel();
    _sub = _repo.authState.listen((user) => add(_AuthUserChanged(user)));
  }

  void _onUserChanged(_AuthUserChanged e, Emitter<AuthState> emit) {
    final user = e.user;
    unawaited(_analytics.setUser(user?.uid));

    emit(
      state.copyWith(
        status: switch (user) {
          null => AuthStatus.signedOut,
          _ when user.isGuest => AuthStatus.guest,
          _ => AuthStatus.signedIn,
        },
        user: user,
        clearUser: user == null,
        isBusy: false,
      ),
    );
  }

  Future<void> _onGoogle(
    GoogleSignInRequested e,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isBusy: true, clearFailure: true));
    final result = await _repo.signInWithGoogle();
    if (emit.isDone) return; // FIXED: Prevent crash if page is closed
    _handleSignInResult(result, emit, 'google');
  }

  Future<void> _onApple(
    AppleSignInRequested e,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isBusy: true, clearFailure: true));
    final result = await _repo.signInWithApple();
    if (emit.isDone) return; // FIXED
    _handleSignInResult(result, emit, 'apple');
  }

  void _handleSignInResult(
    Result<WaveUser> result,
    Emitter<AuthState> emit,
    String method,
  ) {
    result.fold(
      (Failure f) => emit(state.copyWith(isBusy: false, failure: f)),
      (WaveUser user) {
        unawaited(
          _analytics.log(
            AnalyticsEvents.signUpCompleted,
            params: {AnalyticsParams.source: method},
          ),
        );
      },
    );
  }

  Future<void> _onGuest(
    GuestSessionRequested e,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isBusy: true, clearFailure: true));
    final result = await _repo.continueAsGuest();
    if (emit.isDone) return; // FIXED
    
    result.fold(
      (f) => emit(state.copyWith(isBusy: false, failure: f)),
      (_) {},
    );
  }

  Future<void> _onOtpRequested(
    OtpRequested e,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        otpStage: OtpStage.sending,
        isBusy: true,
        clearFailure: true,
      ),
    );

    unawaited(_analytics.log(AnalyticsEvents.otpRequested));
    
    final result = await _repo.sendOtp(e.phoneNumber);
    if (emit.isDone) return; // FIXED
    
    result.fold(
      (f) => emit(
        state.copyWith(otpStage: OtpStage.idle, isBusy: false, failure: f),
      ),
      (verificationId) => emit(
        state.copyWith(
          otpStage: OtpStage.awaitingCode,
          verificationId: verificationId,
          isBusy: false,
        ),
      ),
    );
  }

  Future<void> _onOtpSubmitted(
    OtpSubmitted e,
    Emitter<AuthState> emit,
  ) async {
    final verificationId = state.verificationId;
    if (verificationId == null) {
      emit(
        state.copyWith(
          failure: const AuthFailure(
            'Request a code first',
            reason: FailureReason.requestCodeFirst,
          ),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        otpStage: OtpStage.verifying,
        isBusy: true,
        clearFailure: true,
      ),
    );

    final result = e.linkToExisting
        ? await _repo.linkPhoneToCurrentUser(
            verificationId: verificationId,
            smsCode: e.smsCode,
          )
        : await _repo.verifyOtp(
            verificationId: verificationId,
            smsCode: e.smsCode,
          );
          
    if (emit.isDone) return; // FIXED

    result.fold(
      (f) => emit(
        state.copyWith(
          otpStage: OtpStage.awaitingCode,
          isBusy: false,
          failure: f,
        ),
      ),
      (user) {
        unawaited(_analytics.log(AnalyticsEvents.otpVerificationCompleted));
        emit(
          state.copyWith(
            otpStage: OtpStage.verified,
            user: user,
            isBusy: false,
          ),
        );
      },
    );
  }

  Future<void> _onSignOut(
    SignOutRequested e,
    Emitter<AuthState> emit,
  ) async {
    await _notifications.unregisterDeviceToken();
    await getIt<SavedLocationStore>().clear();
    await _repo.signOut();
    if (emit.isDone) return; // FIXED
    emit(const AuthState(status: AuthStatus.signedOut));
  }

  @override
  Future<void> close() {
    unawaited(_sub?.cancel());
    return super.close();
  }
}
