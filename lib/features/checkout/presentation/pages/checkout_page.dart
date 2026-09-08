import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/error/failure_text.dart';
import 'package:wave/core/error/failures.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_spacing.dart';

import 'package:wave/core/utils/money.dart';
import 'package:wave/design_system/components/wave_button.dart';
import 'package:wave/design_system/components/wave_state_view.dart';
import 'package:wave/design_system/components/wave_text_field.dart';
import 'package:wave/features/cart/domain/entities/cart.dart';
import 'package:wave/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:wave/features/checkout/data/datasources/saved_details_data_source.dart';
import 'package:wave/features/checkout/domain/entities/checkout_gate.dart';
import 'package:wave/features/checkout/domain/entities/delivery_address.dart';
import 'package:wave/features/checkout/domain/entities/payment_method.dart';
import 'package:wave/features/checkout/presentation/bloc/checkout_bloc.dart';
import 'package:wave/features/checkout/presentation/widgets/address_picker_sheet.dart';
import 'package:wave/features/checkout/presentation/widgets/payment_picker_sheet.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({this.sourceReelId, super.key});

  final String? sourceReelId;

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartBloc>().state.cart;
    return BlocProvider(
      create: (_) => getIt<CheckoutBloc>()
        ..add(CheckoutOpened(cart, sourceReelId: sourceReelId)),
      child: const _CheckoutView(),
    );
  }
}

class _CheckoutView extends StatelessWidget {
  const _CheckoutView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.checkout)),
      body: BlocConsumer<CheckoutBloc, CheckoutState>(
        listener: (context, state) {
          if (state.status == CheckoutStatus.success) {
            context.read<CartBloc>().add(const CartCleared());
            context.pushReplacement(
              Routes.orderDetailPath(state.placedOrder!.id),
            );
          }
          if (state.status == CheckoutStatus.failure && state.failure != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_failureMessage(context, state.failure!)),
              ),
            );
          }
        },
        builder: (context, state) {
          // FIXED: Replaced raw CircularProgressIndicator with WaveStateView
          if (state.status == CheckoutStatus.loading) {
            return const WaveStateView(
              state: WaveLoading(SizedBox.shrink()), 
              content: SizedBox.shrink(),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsetsDirectional.all(WaveSpacing.x16),
                  children: [
                    if (!state.gate.canProceedToPayment)
                      _GateCard(gate: state.gate),

                    _Section(
                      title: context.l10n.deliverTo,
                      trailing: WaveButton(
                        variant: WaveButtonVariant.tertiary,
                        size: WaveButtonSize.sm,
                        label: state.addressId == null ? context.l10n.add : context.l10n.change,
                        onPressed: () => _pickAddress(context, state),
                      ),
                      child: state.addressId == null
                          ? Text(
                              context.l10n.noAddressYet,
                              style: context.texts.caption, // FIXED: bodySmall to caption
                            )
                          : Text(
                              context.l10n.savedAddress,
                              style: context.texts.body, // FIXED: bodyMedium to body
                            ),
                    ),

                    _Section(
                      title: context.l10n.payWith,
                      trailing: WaveButton(
                        variant: WaveButtonVariant.tertiary,
                        size: WaveButtonSize.sm,
                        label: context.l10n.change,
                        onPressed: () => _pickPayment(context, state),
                      ),
                      child: Text(
                        state.paymentMethodId == null
                            ? context.l10n.codAvailableNote
                            : PaymentMethod.cash.id == state.paymentMethodId
                                ? context.l10n.railCashOnDelivery
                                : context.l10n.savedPaymentMethod,
                        style: context.texts.body, // FIXED
                      ),
                    ),

                    _PromoField(cart: state.cart),

                    _Section(
                      title: context.l10n.orderSummary,
                      child: Column(
                        children: [
                          for (final line in state.cart.lines)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(bottom: WaveSpacing.x8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      context.l10n.quantityTimesTitle(
                                        line.quantity,
                                        line.product.title,
                                      ),
                                      style: context.texts.body, // FIXED
                                    ),
                                  ),
                                  Text(
                                    context.money(line.lineTotalMinor, line.product.currency),
                                    style: context.texts.body, // FIXED
                                  ),
                                ],
                              ),
                            ),
                          const Divider(),
                          if (state.cart.discountMinor > 0) ...[
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(context.l10n.discount,
                                    style: context.texts.body,), // FIXED
                                Text(
                                  '-${context.money(state.cart.discountMinor, state.cart.currency)}',
                                  style: context.texts.body.copyWith(
                                    color: context.waveColors.success,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: WaveSpacing.x8),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(context.l10n.total,
                                  style: context.texts.title,), // FIXED: titleMedium to title
                              Text(
                                context.money(state.cart.totalMinor, state.cart.currency),
                                style: context.texts.title,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsetsDirectional.all(WaveSpacing.x16),
                decoration: BoxDecoration(
                  color: context.waveColors.surface,
                  border: Border(
                    top: BorderSide(color: context.waveColors.border),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    child: WaveButton( // FIXED: FilledButton to WaveButton
                      label: context.l10n.placeOrderWithTotal(
                        context.money(state.cart.totalMinor, state.cart.currency),
                      ),
                      expand: true,
                      isLoading: state.status == CheckoutStatus.submitting,
                      onPressed: state.canSubmit
                          ? () => context
                              .read<CheckoutBloc>()
                              .add(const CheckoutSubmitted())
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickAddress(BuildContext context, CheckoutState state) async {
    final bloc = context.read<CheckoutBloc>();
    final source = getIt<SavedDetailsDataSource>();

    final saved = await source.addresses();
    if (!context.mounted) return;

    final picked = await showAddressPicker(
      context,
      addresses: saved.valueOrNull ?? const <DeliveryAddress>[],
      selectedId: state.addressId,
    );
    if (picked == null) return;

    final known = (saved.valueOrNull ?? const <DeliveryAddress>[])
        .any((a) => a.id == picked.id);

    if (known) {
      bloc.add(CheckoutAddressSelected(picked.id));
      return;
    }

    final stored = await source.saveAddress(picked);
    stored.fold(
      (f) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(
                SnackBar(content: Text(_failureMessage(context, f))),
              );
        }
      },
      (address) => bloc.add(CheckoutAddressSelected(address.id)),
    );
  }

  Future<void> _pickPayment(BuildContext context, CheckoutState state) async {
    final bloc = context.read<CheckoutBloc>();
    final source = getIt<SavedDetailsDataSource>();

    final results = await Future.wait([
      source.paymentMethods(),
      source.availableRails(),
    ]);
    if (!context.mounted) return;

    final methods = (results[0] as dynamic).valueOrNull as List<PaymentMethod>?;
    final rails = results[1] as Set<PaymentRail>;
    final saved = methods ?? const <PaymentMethod>[];

    final onlyCash = saved.isEmpty &&
        rails.length == 1 &&
        rails.first == PaymentRail.cashOnDelivery;

    if (onlyCash) {
      bloc.add(CheckoutPaymentSelected(PaymentMethod.cash.id));
      return;
    }

    final picked = await showPaymentPicker(
      context,
      savedMethods: saved,
      availableRails: rails,
      selectedId: state.paymentMethodId,
    );
    if (picked != null) bloc.add(CheckoutPaymentSelected(picked.id));
  }

  static String _failureMessage(BuildContext context, Failure f) {
    final promo = _promoRejection(context, f);
    if (promo != null) return promo;
    return _generalMessage(context, f);
  }

  static String? _promoRejection(BuildContext context, Failure f) {
    if (!f.message.startsWith('promo:')) return null;
    return switch (f.message.substring(6)) {
      'expired' => context.l10n.promoExpired,
      'already-used' => context.l10n.promoUsed,
      'below-minimum' => context.l10n.promoInvalid,
      _ => context.l10n.promoInvalid,
    };
  }

  static String _generalMessage(BuildContext context, Failure f) =>
      failureText(context, f);
}

class _GateCard extends StatelessWidget {
  const _GateCard({required this.gate});
  final CheckoutGate gate;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    final (title, body, action, route) = switch (gate) {
      CheckoutGate.needsAccount => (
          context.l10n.signInToOrder,
          context.l10n.signInToOrderBody,
          context.l10n.signIn,
          '${Routes.signIn}?from=${Routes.checkout}',
        ),
      CheckoutGate.needsPhoneVerification => (
          context.l10n.verifyYourPhone,
          context.l10n.phoneGateBody,
          context.l10n.verifyNow,
          '${Routes.phoneVerify}?reason=checkout&from=${Routes.checkout}',
        ),
      CheckoutGate.needsAddress => (
          context.l10n.addDeliveryAddress,
          context.l10n.addAddressBody,
          context.l10n.addAddress,
          Routes.checkout,
        ),
      CheckoutGate.needsPaymentMethod => (
          context.l10n.chooseHowToPay,
          context.l10n.chooseHowToPayBody,
          context.l10n.choose,
          Routes.checkout,
        ),
      CheckoutGate.ready => ('', '', '', ''),
    };

    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: WaveSpacing.x16),
      padding: const EdgeInsetsDirectional.all(WaveSpacing.x16),
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(context.surfaces.radiusCard),
        border: Border.all(color: c.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.texts.title), // FIXED
          const SizedBox(height: WaveSpacing.x4), // Adjust to 4px scale
          Text(body, style: context.texts.caption), // FIXED
          const SizedBox(height: WaveSpacing.x12),
          WaveButton(
            label: action,
            onPressed: () async {
              await context.push(route);
              if (context.mounted) {
                context.read<CheckoutBloc>().add(const CheckoutGateRechecked());
              }
            },
          ),
        ],
      ),
    );
  }
}

class _PromoField extends StatefulWidget {
  const _PromoField({required this.cart});

  final Cart cart;

  @override
  State<_PromoField> createState() => _PromoFieldState();
}

class _PromoFieldState extends State<_PromoField> {
  final _controller = TextEditingController();
  bool _expanded = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final applied = widget.cart.promoCode;

    if (applied != null) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(bottom: WaveSpacing.x20),
        child: Row(
          children: [
            Icon(Icons.local_offer_outlined,
                size: WaveSpacing.x16, color: context.waveColors.success,),
            const SizedBox(width: WaveSpacing.x8),
            Expanded(
              child: Text(applied, style: context.texts.label), // FIXED
            ),
            WaveButton(
              variant: WaveButtonVariant.tertiary,
              size: WaveButtonSize.sm,
              label: context.l10n.remove,
              onPressed: () {
                context.read<CartBloc>().add(const CartPromoRemoved());
                _controller.clear();
              },
            ),
          ],
        ),
      );
    }

    if (!_expanded) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: WaveButton(
          variant: WaveButtonVariant.tertiary,
          icon: Icons.local_offer_outlined,
          label: context.l10n.promoCodeHint,
          onPressed: () => setState(() => _expanded = true),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: WaveSpacing.x20),
      child: Row(
        children: [
          Expanded(
            child: WaveTextField( // FIXED: TextField to WaveTextField
              label: context.l10n.promoCode,
              controller: _controller,
              forceLtr: true, // Replaces textDirection: TextDirection.ltr
            ),
          ),
          const SizedBox(width: WaveSpacing.x8),
          WaveButton(
            variant: WaveButtonVariant.secondary,
            label: context.l10n.apply,
            onPressed: () {
              final code = _controller.text.trim();
              if (code.isEmpty) return;
              context.read<CartBloc>().add(CartPromoApplied(code));
            },
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: WaveSpacing.x20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: context.texts.title), // FIXED
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: WaveSpacing.x4),
          child,
        ],
      ),
    );
  }
}
