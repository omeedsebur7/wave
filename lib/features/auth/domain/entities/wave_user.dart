import 'package:equatable/equatable.dart';

class WaveUser extends Equatable {
  const WaveUser({
    required this.uid,
    required this.isGuest,
    required this.phoneVerified,
    this.displayName,
    this.email,
    this.phoneNumber,
    this.photoUrl,
    this.acceptedTermsVersion,
    this.ageConfirmed = false,
    this.isSuspended = false,
  });

  final String uid;

  /// Anonymous session. Can browse; cannot order, publish, or comment.
  final bool isGuest;

  /// Set by the verification Cloud Function, never by the client.
  final bool phoneVerified;
  final bool isSuspended;

  final String? displayName;
  final String? email;
  final String? phoneNumber;
  final String? photoUrl;

  final String? acceptedTermsVersion;
  final bool ageConfirmed;

  bool get canCheckout => !isGuest && phoneVerified;
  bool get canComment => !isGuest;

  // FIXED: Added all missing properties so state comparisons are accurate!
  @override
  List<Object?> get props => [
        uid,
        isGuest,
        phoneVerified,
        isSuspended,
        displayName,
        email,
        phoneNumber,
        photoUrl,
        acceptedTermsVersion,
        ageConfirmed,
      ];
}
