/// What still stands between this user and a completed order.
///
/// Modelled as an explicit enum rather than a pile of booleans at the call site,
/// so the checkout flow can't accidentally skip a step and so the "one-tap"
/// fast path is a single, obvious condition.
enum CheckoutGate {
  /// Guest — has to become an account before an order can exist (§1).
  needsAccount,

  /// Signed in via Google/Apple but no verified phone on file. Enforced ONCE
  /// per user, not per order (§5.2).
  needsPhoneVerification,

  needsAddress,
  needsPaymentMethod,

  /// Everything on file — genuine one-tap purchase (§5.1).
  ready;

  bool get canProceedToPayment => this == CheckoutGate.ready;
}

class CheckoutReadiness {
  const CheckoutReadiness({
    required this.isGuest,
    required this.hasVerifiedPhone,
    required this.hasSavedAddress,
    required this.hasPaymentMethod,
  });

  final bool isGuest;
  final bool hasVerifiedPhone;
  final bool hasSavedAddress;
  final bool hasPaymentMethod;

  /// Order matters: identity before logistics. Asking someone to enter an
  /// address and then bouncing them to phone verification is the kind of
  /// sequencing that loses a sale.
  CheckoutGate get gate {
    if (isGuest) return CheckoutGate.needsAccount;
    if (!hasVerifiedPhone) return CheckoutGate.needsPhoneVerification;
    if (!hasSavedAddress) return CheckoutGate.needsAddress;
    if (!hasPaymentMethod) return CheckoutGate.needsPaymentMethod;
    return CheckoutGate.ready;
  }

  bool get supportsOneTap => gate == CheckoutGate.ready;
}
