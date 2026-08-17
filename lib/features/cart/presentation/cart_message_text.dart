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
      CartMessage.addedToCart => context.l10n.addedToCart,
      CartMessage.stockLimitReached => context.l10n.stockLimitReached,
      CartMessage.promoApplied => context.l10n.promoApplied,
      CartMessage.promoInvalid => context.l10n.promoInvalid,
      CartMessage.promoExpired => context.l10n.promoExpired,
      CartMessage.promoUsed => context.l10n.promoUsed,
      CartMessage.promoBelowMinimum => context.l10n.promoBelowMinimum,
    };
