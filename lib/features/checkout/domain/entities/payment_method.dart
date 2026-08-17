import 'package:equatable/equatable.dart';
import 'package:wave/features/checkout/data/datasources/saved_details_data_source.dart' show SavedDetailsDataSource;

/// Payment rails, per §5.2.
///
/// Cash on delivery is listed first and enabled by default because it still
/// leads most Iraqi online orders by trust — treating it as a fallback rather
/// than the primary option would misread the market.
///
/// PHASE 1 STATUS: cash on delivery only, by explicit product decision. The
/// other four rails are defined, their adapters exist, and they are excluded
/// from every surface a buyer can reach — see [phase1EnabledRails]. They are
/// not deleted, because Phase 2 turning one back on should be a one-line
/// change to that constant, not a rebuild of the payment abstraction.
enum PaymentRail {
  cashOnDelivery,
  zainCash,
  asiaHawala,
  qiCard,
  bankCard;

  /// The Phase 1 floor. Every UI surface, and [SavedDetailsDataSource], reads
  /// this rather than a server-side config document.
  ///
  /// Deliberately a compile-time constant and not Remote Config. A dashboard
  /// document is exactly the kind of thing a typo or a stale cache re-enables
  /// by accident, and "we took an online payment during the cash-only phase"
  /// is a far worse failure than "the flag lives in code and needs a release
  /// to change" — which is the point, not a limitation.
  static const Set<PaymentRail> phase1EnabledRails = {PaymentRail.cashOnDelivery};

  /// True for any rail this build will actually offer.
  bool get isEnabledThisPhase => phase1EnabledRails.contains(this);

  /// Provider names are proper nouns and stay untranslated — "ZainCash" is
  /// ZainCash in every language, and translating it would make the option
  /// unrecognisable next to the provider's own branding.
  ///
  /// The two generic rails have translated labels; see `paymentRailLabel`.
  String get brandName => switch (this) {
        PaymentRail.zainCash => 'ZainCash',
        PaymentRail.asiaHawala => 'AsiaHawala',
        PaymentRail.qiCard => 'Qi Card',
        PaymentRail.cashOnDelivery => '',
        PaymentRail.bankCard => '',
      };

  bool get isBranded => brandName.isNotEmpty;

  /// COD skips the gateway entirely — no provider call, no webhook, and the
  /// order goes straight to confirmed.
  bool get requiresGateway => this != PaymentRail.cashOnDelivery;
}

class PaymentMethod extends Equatable {
  const PaymentMethod({
    required this.id,
    required this.rail,
    this.displayLabel,
    this.lastFour,
    this.isDefault = false,
  });

  /// Cash needs no stored method, so this constant stands in for it and keeps
  /// the checkout flow from special-casing null.
  static const cash = PaymentMethod(
    id: 'cash_on_delivery',
    rail: PaymentRail.cashOnDelivery,
  );

  final String id;
  final PaymentRail rail;
  final String? displayLabel;

  /// Only ever the last four digits and a provider token. Full card data never
  /// touches Firestore or the device — it lives with the payment provider.
  final String? lastFour;

  final bool isDefault;

  /// Only meaningful for branded rails; generic ones are resolved through
  /// `paymentRailLabel` at render, where a BuildContext exists.
  String get title => displayLabel ?? rail.brandName;

  String? get maskedNumber => lastFour == null ? null : '•••• $lastFour';

  @override
  List<Object?> get props => [id, rail, lastFour, isDefault];
}
