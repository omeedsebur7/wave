import 'package:flutter/widgets.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/features/marketplace/domain/entities/product.dart';

/// Resolves a [ProductSort] to display text.
///
/// Lives in the presentation layer because that is the only layer with a
/// `BuildContext`. The enum deliberately carries no `label` of its own — an enum
/// constant cannot reach a context, so a label defined there is guaranteed to be
/// the one string on the screen that never translates.
///
/// This is the fifth enum in this codebase to have had its labels moved out for
/// exactly this reason. It is a structural trap in Dart rather than an
/// oversight: putting the label next to the value reads as good cohesion and is
/// the single reliable way to make a string untranslatable.
String productSortLabel(BuildContext context, ProductSort sort) =>
    switch (sort) {
      ProductSort.newest => context.l10n.sortNewest,
      ProductSort.priceLowToHigh => context.l10n.sortPriceLowToHigh,
      ProductSort.priceHighToLow => context.l10n.sortPriceHighToLow,
      ProductSort.topRated => context.l10n.sortTopRated,
    };
