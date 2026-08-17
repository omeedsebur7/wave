import 'package:flutter/material.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/features/checkout/domain/entities/payment_method.dart';
import 'package:wave/features/checkout/presentation/payment_rail_text.dart';

/// Payment method picker.
///
/// Only rails actually enabled for the current market are shown — a greyed-out
/// list of things you cannot use is worse than a short list of things you can.
/// Availability comes from Remote Config so a rail can be switched on per
/// market without a release.
Future<PaymentMethod?> showPaymentPicker(
  BuildContext context, {
  required List<PaymentMethod> savedMethods,
  required Set<PaymentRail> availableRails,
  String? selectedId,
}) {
  return showModalBottomSheet<PaymentMethod>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _PaymentPickerSheet(
      savedMethods: savedMethods,
      availableRails: availableRails,
      selectedId: selectedId,
    ),
  );
}

class _PaymentPickerSheet extends StatelessWidget {
  const _PaymentPickerSheet({
    required this.savedMethods,
    required this.availableRails,
    this.selectedId,
  });

  final List<PaymentMethod> savedMethods;
  final Set<PaymentRail> availableRails;
  final String? selectedId;

  /// Whether the "add a payment method" section below the divider has anything
  /// to show.
  ///
  /// Mirrors the loop's condition exactly rather than approximating it. If the
  /// two ever disagree, the divider reappears above an empty section — which is
  /// the precise bug this getter exists to prevent, so it is worth the
  /// duplication being obvious and adjacent rather than clever.
  bool get _hasRailsToAdd => availableRails.any(
        (rail) =>
            rail.requiresGateway &&
            !savedMethods.any((m) => m.rail == rail),
      );

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final codAvailable = availableRails.contains(PaymentRail.cashOnDelivery);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.howDoYouWantToPay,
              style: context.texts.headlineMedium,),
          const SizedBox(height: 12),

          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                if (codAvailable)
                  _MethodTile(
                    method: PaymentMethod.cash,
                    selected: selectedId == PaymentMethod.cash.id,
                    icon: Icons.payments_outlined,
                    onTap: () => Navigator.pop(context, PaymentMethod.cash),
                  ),

                for (final method in savedMethods)
                  _MethodTile(
                    method: method,
                    selected: selectedId == method.id,
                    icon: _iconFor(method.rail),
                    onTap: () => Navigator.pop(context, method),
                  ),

                // Only drawn when something follows it.
                //
                // In Phase 1 cash is the only rail, so the "add a payment
                // method" loop below yields nothing — and an unconditional
                // divider left a horizontal line hanging under the last item
                // with empty space beneath, which reads as a rendering bug
                // rather than a deliberately short list.
                if (_hasRailsToAdd) const Divider(height: 24),

                for (final rail in availableRails)
                  if (rail.requiresGateway &&
                      !savedMethods.any((m) => m.rail == rail))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(_iconFor(rail), color: c.textSecondary),
                      title: Text(
                        context.l10n.addPaymentMethod(
                          paymentRailLabel(context, rail),
                        ),
                        style: context.texts.bodyMedium,
                      ),
                      subtitle: Text(
                        paymentRailDescription(context, rail),
                        style: context.texts.bodySmall,
                      ),
                      trailing: const Icon(Icons.add, size: 20),
                      // Adding a wallet or card hands off to the provider's own
                      // enrolment flow, which is wired per provider. Until one
                      // is live, saying so beats a tap that does nothing.
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          // `rail.label` did not exist — PaymentRail defines
                          // `brandName`. This line could not compile, which is
                          // its own evidence that nobody reached this SnackBar:
                          // in the cash-only phase the loop it sits in yields
                          // nothing. Now localized, and named correctly.
                          content: Text(
                            context.l10n.railNotConnectedYet(
                              paymentRailLabel(context, rail),
                            ),
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),

          // Only shown when a card or wallet can actually be added.
          //
          // It reassures people about how card data is handled — genuinely
          // worth saying, but only once there is a card to hand over. On a
          // cash-only sheet it answers a question nobody asked and implies a
          // capability the app does not currently have, which costs trust
          // rather than building it.
          if (_hasRailsToAdd) ...[
            const SizedBox(height: 8),
            Text(
              context.l10n.cardDetailsNote,
              style: context.texts.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  static IconData _iconFor(PaymentRail rail) => switch (rail) {
        PaymentRail.cashOnDelivery => Icons.payments_outlined,
        PaymentRail.zainCash || PaymentRail.asiaHawala =>
          Icons.account_balance_wallet_outlined,
        PaymentRail.qiCard || PaymentRail.bankCard => Icons.credit_card,
      };
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.method,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: selected ? c.primary : c.textSecondary),
      title: Text(paymentMethodTitle(context, method),
          style: context.texts.labelMedium,),
      subtitle: Text(paymentMethodSubtitle(context, method),
          style: context.texts.bodySmall,),
      trailing: selected ? Icon(Icons.check, color: c.primary) : null,
      onTap: onTap,
    );
  }
}
