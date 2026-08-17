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

  /// Set by the verification Cloud Function, never by the client. This is the
  /// flag the checkout gate reads (§5.2).
  final bool phoneVerified;
  final bool isSuspended;

  final String? displayName;
  final String? email;
  final String? phoneNumber;
  final String? photoUrl;

  /// Versioned so a material change to Terms can trigger re-acceptance (§7).
  final String? acceptedTermsVersion;

  final bool ageConfirmed;

  bool get canCheckout => !isGuest && phoneVerified;
  bool get canComment => !isGuest;

  @override
  List<Object?> get props => [isSuspended, uid, isGuest, phoneVerified, acceptedTermsVersion];
}
