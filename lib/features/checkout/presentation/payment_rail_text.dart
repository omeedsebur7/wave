import 'package:flutter/widgets.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/features/checkout/domain/entities/payment_method.dart';

/// Resolves a payment rail to display text.
///
/// Brand names pass through untranslated — "ZainCash" is ZainCash in every
/// language, and translating it would make the option unrecognisable beside
/// the provider's own branding. Only the generic rails and the descriptions
/// are localized.
String paymentRailLabel(BuildContext context, PaymentRail rail) =>
    switch (rail) {
      PaymentRail.cashOnDelivery => context.l10n.railCashOnDelivery,
      PaymentRail.bankCard => context.l10n.railBankCard,
      _ => rail.brandName,
    };

String paymentRailDescription(BuildContext context, PaymentRail rail) =>
    switch (rail) {
      PaymentRail.cashOnDelivery => context.l10n.railCashOnDeliveryBody,
      PaymentRail.zainCash || PaymentRail.asiaHawala =>
        context.l10n.railMobileWallet,
      PaymentRail.qiCard => context.l10n.railCard,
      PaymentRail.bankCard => context.l10n.railBankCardBody,
    };

String paymentMethodTitle(BuildContext context, PaymentMethod method) =>
    method.displayLabel ?? paymentRailLabel(context, method.rail);

String paymentMethodSubtitle(BuildContext context, PaymentMethod method) =>
    method.maskedNumber ?? paymentRailDescription(context, method.rail);
