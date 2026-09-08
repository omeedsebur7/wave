import 'package:flutter/widgets.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/features/cart/presentation/bloc/cart_bloc.dart';

/// Resolves a [CartMessage] to localized text.
///
/// Lives in the presentation layer because that is the only layer with a
/// BuildContext. The BLoC emits the key; this turns it into words in whatever
/// language the user is currently reading.
String cartMessageText(BuildContext context, CartMessage message) =>
    switch (message) {
      CartMessage.addedToCart => context.l10n.cartAddedToCart,
      CartMessage.stockLimitReached => context.l10n.cartStockLimitReached,
      CartMessage.outOfStock => context.l10n.cartOutOfStock,
      CartMessage.promoApplied => context.l10n.cartPromoApplied,
      CartMessage.promoInvalid => context.l10n.cartPromoInvalid,
      CartMessage.promoExpired => context.l10n.cartPromoExpired,
      CartMessage.promoUsed => context.l10n.cartPromoUsed,
      CartMessage.promoBelowMinimum => context.l10n.cartPromoBelowMinimum,
    };
