import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/error/failure_text.dart';
import 'package:wave/core/error/failures.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_surfaces.dart';
import 'package:wave/core/utils/money.dart';
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
          if (state.status == CheckoutStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // The gate is the first thing on screen when it applies.
                    // Burying it below the address form means someone fills
                    // in an address and then gets stopped.
                    if (!state.gate.canProceedToPayment)
                      _GateCard(gate: state.gate),

                    _Section(
                      title: context.l10n.deliverTo,
                      trailing: TextButton(
                        onPressed: () => _pickAddress(context, state),
                        child: Text(
                          state.addressId == null
                              ? context.l10n.add
                              : context.l10n.change,
                        ),
                      ),
                      child: state.addressId == null
                          ? Text(
                              context.l10n.noAddressYet,
                              style: context.texts.bodySmall,
                            )
                          : Text(
                              context.l10n.savedAddress,
                              style: context.texts.bodyMedium,
                            ),
                    ),

                    _Section(
                      title: context.l10n.payWith,
                      trailing: TextButton(
                        onPressed: () => _pickPayment(context, state),
                        child: Text(context.l10n.change),
                      ),
                      child: Text(
                        state.paymentMethodId == null
                            ? context.l10n.codAvailableNote
                            : PaymentMethod.cash.id == state.paymentMethodId
                                ? context.l10n.railCashOnDelivery
                                : context.l10n.savedPaymentMethod,
                        style: context.texts.bodyMedium,
                      ),
                    ),

                    _PromoField(cart: state.cart),

                    _Section(
                      title: context.l10n.orderSummary,
                      child: Column(
                        children: [
                          for (final line in state.cart.lines)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      context.l10n.quantityTimesTitle(
                          line.quantity,
                          line.product.title,
                        ),
                                      style: context.texts.bodyMedium,
                                    ),
                                  ),
                                  Text(
                                    context.money(line.lineTotalMinor, line.product.currency),
                                    style: context.texts.bodyMedium,
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
                                    style: context.texts.bodyMedium,),
                                Text(
                                  '-${context.money(state.cart.discountMinor, state.cart.currency)}',
                                  style: context.texts.bodyMedium?.copyWith(
                                    color: context.waveColors.success,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(context.l10n.total,
                                  style: context.texts.titleMedium,),
                              Text(
                                context.money(state.cart.totalMinor, state.cart.currency),
                                style: context.texts.titleMedium,
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
                padding: const EdgeInsets.all(16),
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
                    child: FilledButton(
                      onPressed: state.canSubmit
                          ? () => context
                              .read<CheckoutBloc>()
                              .add(const CheckoutSubmitted())
                          : null,
                      style:
                          FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                      child: state.status == CheckoutStatus.submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              context.l10n.placeOrderWithTotal(
                                context.money(state.cart.totalMinor, state.cart.currency),
                              ),
                            ),
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

    // A picker result with a client-generated id is a NEW address that still
    // has to be persisted; anything already saved comes back with its
    // Firestore id and is used directly.
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

    // With one option, choose it instead of asking.
    //
    // Phase 1 is cash-only, so the sheet would open, ask "How do you want to
    // pay?", and offer a single answer. That is a wasted tap on the app's core
    // conversion path, and it reads as the app not knowing its own state.
    //
    // Written as a general condition rather than an `if cash-only` special
    // case: it stays correct when Phase 2 adds rails, and stays correct for a
    // returning buyer who has exactly one saved method and no others to add.
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

  /// Errors say what happened and what to do. They don't apologise and they
  /// aren't vague.
  ///
  /// Promo rejections arrive from the server as `promo:<reason>` — the code
  /// is revalidated there, so the reason has to travel back rather than being
  /// guessed at locally.
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
      // not-found, inactive, exhausted and wrong-seller all mean the same
      // thing to the person typing: this code will not work here. Spelling
      // out which internal state they hit tells an attacker how to probe the
      // code space.
      _ => context.l10n.promoInvalid,
    };
  }

  /// Everything that is not a promo rejection is a plain failure, and every
  /// failure now carries a reason that `failureText` knows how to translate.
  ///
  /// This used to be a local switch returning English sentences, ending in
  /// `_ => f.message` — which rendered a string written in the data layer
  /// straight into a SnackBar at the most expensive moment in the app.
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(WaveSurfaces.radiusCard),
        border: Border.all(color: c.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.texts.titleMedium),
          const SizedBox(height: 6),
          Text(body, style: context.texts.bodySmall),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () async {
              await context.push(route);
              if (context.mounted) {
                context.read<CheckoutBloc>().add(const CheckoutGateRechecked());
              }
            },
            child: Text(action),
          ),
        ],
      ),
    );
  }
}

/// Promo code entry (§5.2).
///
/// The discount shown here is a PREVIEW. `placeOrder` revalidates the code
/// server-side and computes the real figure — a client-supplied discount is a
/// client-supplied price. If the server rejects it, the order fails with a
/// reason rather than silently charging the undiscounted total, because
/// someone who typed a code and watched the total drop must not be charged
/// full price without being told.
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
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          children: [
            Icon(Icons.local_offer_outlined,
                size: 18, color: context.waveColors.success,),
            const SizedBox(width: 8),
            Expanded(
              child: Text(applied, style: context.texts.labelMedium),
            ),
            TextButton(
              onPressed: () {
                context.read<CartBloc>().add(const CartPromoRemoved());
                _controller.clear();
              },
              child: Text(context.l10n.remove),
            ),
          ],
        ),
      );
    }

    if (!_expanded) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          onPressed: () => setState(() => _expanded = true),
          icon: const Icon(Icons.local_offer_outlined, size: 18),
          label: Text(context.l10n.promoCodeHint),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: context.l10n.promoCode,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: () {
              final code = _controller.text.trim();
              if (code.isEmpty) return;
              context.read<CartBloc>().add(CartPromoApplied(code));
            },
            child: Text(context.l10n.apply),
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
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: context.texts.titleMedium),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}
