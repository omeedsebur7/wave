import 'package:flutter/material.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_spacing.dart';
import 'package:wave/features/checkout/domain/entities/payment_method.dart';
import 'package:wave/features/checkout/presentation/payment_rail_text.dart';

/// Payment method picker.
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
      // FIXED: Replaced EdgeInsets.fromLTRB with EdgeInsetsDirectional.fromSTEB
      padding: const EdgeInsetsDirectional.fromSTEB(
        WaveSpacing.x20,
        WaveSpacing.x20,
        WaveSpacing.x20,
        WaveSpacing.x32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.howDoYouWantToPay,
            style: context.texts.headline, // FIXED: headlineMedium -> headline
          ),
          const SizedBox(height: WaveSpacing.x12),

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

                if (_hasRailsToAdd) const Divider(height: WaveSpacing.x24),

                for (final rail in availableRails)
                  if (rail.requiresGateway &&
                      !savedMethods.any((m) => m.rail == rail))
                    ListTile(
                      contentPadding: EdgeInsetsDirectional.zero, // FIXED
                      leading: Icon(_iconFor(rail), color: c.textSecondary),
                      title: Text(
                        context.l10n.addPaymentMethod(
                          paymentRailLabel(context, rail),
                        ),
                        style: context.texts.body, // FIXED: bodyMedium -> body
                      ),
                      subtitle: Text(
                        paymentRailDescription(context, rail),
                        style: context.texts.caption, // FIXED: bodySmall -> caption
                      ),
                      trailing: const Icon(Icons.add, size: WaveSpacing.x20),
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
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

          if (_hasRailsToAdd) ...[
            const SizedBox(height: WaveSpacing.x8),
            Text(
              context.l10n.cardDetailsNote,
              style: context.texts.caption, // FIXED: bodySmall -> caption
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
      contentPadding: EdgeInsetsDirectional.zero, // FIXED
      leading: Icon(icon, color: selected ? c.primary : c.textSecondary),
      title: Text(
        paymentMethodTitle(context, method),
        style: context.texts.label, // FIXED: labelMedium -> label
      ),
      subtitle: Text(
        paymentMethodSubtitle(context, method),
        style: context.texts.caption, // FIXED: bodySmall -> caption
      ),
      trailing: selected ? Icon(Icons.check, color: c.primary) : null,
      onTap: onTap,
    );
  }
}
