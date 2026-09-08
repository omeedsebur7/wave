import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:wave/l10n/generated/app_localizations.dart';

/// Turns [CartMessage] into a SnackBar, once, for the whole app.
///
/// Mounted in MaterialApp.builder rather than on each screen. The cart can be
/// added to from the PDP, from Reels Buy Now, from a recommendation rail and
/// from the cart page itself, and a listener per screen would mean four places
/// that drift — including four chances for one of them to say something other
/// than what the button said.
///
/// §3.2: an action keeps its name through the flow. The button says
/// `pdpAddToCart`, this says `cartAddedToCart`, and they have to agree in
/// Kurdish, not only in English.
class CartMessageListener extends StatelessWidget {
  const CartMessageListener({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<CartBloc, CartState>(
      listenWhen: (_, next) => next.message != null,
      listener: (context, state) {
        final message = state.message;
        if (message == null) return;

        final l = AppLocalizations.of(context);
        final c = context.waveColors;

        final (String text, bool isError) = switch (message) {
          CartMessage.addedToCart => (l.cartAddedToCart, false),
          CartMessage.stockLimitReached => (l.cartStockLimitReached, true),
          CartMessage.outOfStock => (l.cartOutOfStock, true),
          CartMessage.promoApplied => (l.cartPromoApplied, false),
          CartMessage.promoInvalid => (l.cartPromoInvalid, true),
          CartMessage.promoExpired => (l.cartPromoExpired, true),
          CartMessage.promoUsed => (l.cartPromoUsed, true),
          CartMessage.promoBelowMinimum => (l.cartPromoBelowMinimum, true),
        };

        ScaffoldMessenger.of(context)
          // Without this, adding three items in quick succession queues three
          // snackbars and the third is still on screen well after the action.
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(text),
              backgroundColor: isError ? c.error : null,
              duration: context.motion.deliberate * 5,
            ),
          );
      },
      child: child,
    );
  }
}
