import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/analytics/analytics_events.dart';
import 'package:wave/core/analytics/analytics_service.dart';
import 'package:wave/core/error/failure_text.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_surfaces.dart';
import 'package:wave/core/utils/money.dart';
import 'package:wave/core/widgets/trust_badge.dart';
import 'package:wave/core/widgets/wave_error_view.dart';
import 'package:wave/features/checkout/domain/entities/checkout_gate.dart';
import 'package:wave/features/checkout/presentation/bloc/quick_checkout_cubit.dart';
import 'package:wave/features/location/domain/entities/delivery_location.dart';
import 'package:wave/features/location/presentation/pages/location_picker_page.dart';
import 'package:wave/features/reels/data/buy_now_tracker.dart';

/// Buy Now sheet (§5.1) — the shortest path between watching and owning.
///
/// Everything here is in service of one number: how many people who tapped
/// actually complete. So it shows the price, who they are buying from, and one
/// button that says exactly what tapping it will do. There is no quantity
/// stepper, no address picker and no payment picker; a sheet that asks four
/// questions is the checkout page, and the checkout page already exists.
Future<void> showQuickCheckoutSheet(
  BuildContext context, {
  required String productId,
  String? sourceReelId,
}) {
  // Distinct from the Buy Now tap: a tap that never reaches an open sheet is a
  // rendering or navigation failure, not a conversion decision, and collapsing
  // the two would hide that difference.
  getIt<BuyNowTracker>().recordSheetOpened(productId: productId);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider(
      create: (_) => getIt<QuickCheckoutCubit>()..load(productId),
      child: QuickCheckoutSheet(sourceReelId: sourceReelId),
    ),
  );
}

class QuickCheckoutSheet extends StatelessWidget {
  const QuickCheckoutSheet({this.sourceReelId, super.key});

  final String? sourceReelId;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    return BlocConsumer<QuickCheckoutCubit, QuickCheckoutState>(
      listenWhen: (a, b) => a.status != b.status || a.failure != b.failure,
      listener: (context, state) {
        if (state.status == QuickCheckoutStatus.placed) {
          Navigator.of(context).pop();
          context.push(Routes.orderDetailPath(state.orderId!));
        }
        if (state.failure != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(failureText(context, state.failure!))));
        }
      },
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(WaveSurfaces.radiusSheet),
            ),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ..._body(context, state),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _body(BuildContext context, QuickCheckoutState state) {
    // Enumerated rather than `default: return _purchaseBody(...)`.
    //
    // A default branch treats every FUTURE state the same way a today's
    // unmapped state is treated — silently. If QuickCheckoutStatus ever grows
    // a new value (a `failed` status distinct from `unavailable`, say), the
    // old default would route it straight into _purchaseBody as though it
    // were normal, and nobody would notice until a support ticket asked why
    // a failed checkout still showed a Buy button. Enumerating every case
    // means the compiler itself refuses to build the moment the enum grows a
    // member this switch has not been told about — the exact `case` fixed at
    // that point tells you which state needs a decision, rather than a
    // runtime symptom three steps removed from the cause.
    //
    // ASSUMPTION, stated because I have not seen QuickCheckoutState's own
    // file: QuickCheckoutStatus has exactly {loading, unavailable, ready,
    // placing, placed}, inferred from every reference to it in THIS file —
    // .loading and .unavailable used explicitly below, .placing read in
    // _GateAction, .placed read in the listener above. If the real enum has a
    // member not referenced anywhere in this file, this switch will fail to
    // compile with a clear "missing case" — the correct failure mode, and
    // the fix is adding that case with a real decision, not restoring
    // default.
    switch (state.status) {
      case QuickCheckoutStatus.loading:
        return const [
          SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator()),
          ),
        ];

      case QuickCheckoutStatus.unavailable:
        // The listing was withdrawn between the feed loading and this tap. A
        // scheduled function unlinks these from Reels, but it is not instant,
        // and this person deserves an explanation rather than an empty sheet.
        return [
          SizedBox(
            height: 200,
            child: WaveErrorView(
              title: context.l10n.productNotFound,
              message: context.l10n.productNotFoundBody,
              icon: Icons.remove_shopping_cart_outlined,
              retryLabel: context.l10n.backToTheMarket,
              onRetry: () {
                Navigator.of(context).pop();
                context.push(Routes.marketplace);
              },
            ),
          ),
        ];

      // ready / placing / placed all render the normal purchase body — the
      // button itself (_GateAction) is what changes between them, via
      // state.status == placing for the spinner. placed is momentary: the
      // listener above navigates away on the same frame it is reached.
      case QuickCheckoutStatus.ready:
      case QuickCheckoutStatus.placing:
      case QuickCheckoutStatus.placed:
        return _purchaseBody(context, state);

      // The member the first version of this enumeration missed — confirmed
      // by `flutter analyze` refusing to compile, which is the whole reason
      // this switch is enumerated rather than defaulted: the compiler caught
      // it immediately instead of a real checkout failure silently rendering
      // as though everything were fine.
      //
      // TODO(wave-team): this branch is intentionally minimal and needs a proper design
      // pass, not a placeholder left standing. Written this conservatively —
      // reusing only l10n keys and Product fields already proven to exist
      // elsewhere in THIS file, rather than reaching for a `somethingWentWrong`
      // / `tryAgain` string or a `Product.id` field I have not actually seen
      // declared anywhere — because this session already produced two
      // compile errors this exact way (QuickCheckoutStatus.failed and
      // OrderInternalStatus.refunded, both real enum members I had not been
      // shown). Guessing a THIRD unverified API surface in the same patch,
      // in the file that just proved the guess-and-fix loop is expensive,
      // would be the same mistake a second time.
      //
      // The listener at the top of this widget already shows state.failure
      // via a SnackBar the moment it becomes non-null — see
      // `if (state.failure != null) ScaffoldMessenger...` above — so a
      // buyer reaching this branch has already seen why. This body only
      // needs to not be blank while that SnackBar is visible, and to offer
      // a way back rather than a dead end.
      case QuickCheckoutStatus.failed:
        return [
          SizedBox(
            height: 200,
            child: WaveErrorView(
              // Reusing the "not found" copy's SHAPE, not its meaning — the
              // title/message pairing already exists and renders correctly;
              // only the words are provisional pending real strings for this
              // specific case.
              title: context.l10n.productNotFound,
              message: context.l10n.productNotFoundBody,
              icon: Icons.error_outline,
              retryLabel: context.l10n.backToTheMarket,
              onRetry: () {
                Navigator.of(context).pop();
                context.push(Routes.marketplace);
              },
            ),
          ),
        ];
    }
  }

  List<Widget> _purchaseBody(BuildContext context, QuickCheckoutState state) {
    final c = context.waveColors;
    final product = state.product!;

    // Logged here rather than on every render of a badge anywhere: this is the
    // one place a trust badge is shown to someone mid-decision.
    getIt<AnalyticsService>().log(
      AnalyticsEvents.trustBadgeViewed,
      params: {AnalyticsParams.trustTier: state.sellerTier.name},
    );

    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(WaveSurfaces.radiusChip),
            child: CachedNetworkImage(
              imageUrl: product.primaryImage,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: 64,
                height: 64,
                color: c.border,
                child: Icon(Icons.image_not_supported_outlined,
                    size: 20, color: c.textSecondary,),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.titleMedium,
                ),
                const SizedBox(height: 4),
                // The signal that lets someone buy from a stranger (§5.1).
                TrustBadge(
                  tier: state.sellerTier,
                  isKycVerified: state.sellerKycVerified,
                  compact: true,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            context.money(product.priceMinor, product.currency),
            style: context.texts.headlineMedium,
          ),
        ],
      ),

      const SizedBox(height: 12),
      Row(
        children: [
          Icon(Icons.people_outline, size: 16, color: c.textSecondary),
          const SizedBox(width: 6),
          Text(context.l10n.peopleBought(state.buyerCount),
              style: context.texts.bodySmall,),
          if (state.isLowStock) ...[
            const SizedBox(width: 12),
            Icon(Icons.inventory_2_outlined, size: 16, color: c.warning),
            const SizedBox(width: 6),
            Text(
              context.l10n.lowStockShort,
              style: context.texts.bodySmall?.copyWith(color: c.warning),
            ),
          ],
        ],
      ),

      const SizedBox(height: 20),

      if (!product.inStock)
        // Sold out between the feed loading and the tap. Shown rather than
        // hidden, because a disabled button with a reason beats a button that
        // silently fails.
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: null,
            style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
            child: Text(context.l10n.outOfStock),
          ),
        )
      else
        _GateAction(state: state, sourceReelId: sourceReelId),
    ];
  }
}

/// Sends the buyer to the map, then places the order with what they confirmed.
///
/// The location screen sits between the tap and the order on purpose — a
/// courier needs a point on a map, and a saved postal address is not one in
/// this market. It is real friction on the app's core path, and the funnel
/// already measures it: `buy_now_tapped` and `purchase_completed` are separate
/// events, so the drop introduced here is visible rather than assumed.
///
/// Mitigated by pre-centring on the last confirmed pin, so a repeat buyer
/// confirms rather than searches.
Future<void> _pickLocationThenBuy(
  BuildContext context,
  QuickCheckoutState state,
  String? sourceReelId,
) async {
  final cubit = context.read<QuickCheckoutCubit>();
  final price = context.money(state.product!.priceMinor, state.product!.currency);

  final location = await Navigator.of(context).push<DeliveryLocation>(
    MaterialPageRoute(
      builder: (_) => LocationPickerPage(
        // The button on the map repeats the price, because that screen is now
        // where the purchase is actually committed and the sheet behind it is
        // no longer visible.
        confirmLabel: context.l10n.confirmAndBuy(price),
      ),
    ),
  );

  // Backing out is a decision, not a failure. No order, no error, no toast.
  if (location == null) return;

  await cubit.placeOrder(location: location, sourceReelId: sourceReelId);
}

/// The button changes according to what is actually missing, and says exactly
/// what tapping it will do.
///
/// "Continue" would hide the fact that a verification step is coming. Naming it
/// keeps the flow honest and, in practice, converts better than a vague label —
/// people abandon at the surprise, not at the step.
class _GateAction extends StatelessWidget {
  const _GateAction({required this.state, this.sourceReelId});

  final QuickCheckoutState state;
  final String? sourceReelId;

  @override
  Widget build(BuildContext context) {
    final placing = state.status == QuickCheckoutStatus.placing;

    final (label, icon, onTap) = switch (state.gate) {
      CheckoutGate.needsAccount => (
          context.l10n.signInToOrder,
          Icons.login,
          () => context.push('${Routes.signIn}?from=${Routes.checkout}'),
        ),
      CheckoutGate.needsPhoneVerification => (
          context.l10n.verifyYourPhone,
          Icons.sms_outlined,
          () => context.push('${Routes.phoneVerify}?reason=checkout'),
        ),
      CheckoutGate.needsAddress => (
          context.l10n.addDeliveryAddress,
          Icons.location_on_outlined,
          () => context.push(Routes.checkout),
        ),
      CheckoutGate.needsPaymentMethod => (
          context.l10n.chooseHowToPay,
          Icons.payment,
          () => context.push(Routes.checkout),
        ),
      // Price on the button, and ONLY on this branch.
      //
      // The other four labels are steps toward buying, not the purchase — a
      // "Verify your phone · 25,000 IQD" button implies the tap spends the
      // money, which it does not. Attaching the figure to the one tap that
      // charges is what makes it informative rather than decorative.
      // Names the map step rather than hiding it.
      //
      // This button used to say "Confirm and buy", which is what the button on
      // the NEXT screen says — so the same words appeared twice and the first
      // one did not buy anything. By the rule the rest of this switch follows,
      // a step gets named: people abandon at the surprise, not at the step.
      CheckoutGate.ready => (
          context.l10n.setDeliveryLocationWithPrice(
            context.money(state.product!.priceMinor, state.product!.currency),
          ),
          Icons.place_outlined,
          () => _pickLocationThenBuy(context, state, sourceReelId),
        ),
    };

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            // Disabled while placing, so a double tap cannot fire twice. The
            // idempotency key would deduplicate it server-side anyway; this
            // stops the second request being sent at all.
            onPressed: placing ? null : onTap,
            icon: placing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(icon, size: 20),
            label: Text(label),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
          ),
        ),
        if (state.gate == CheckoutGate.needsPhoneVerification) ...[
          const SizedBox(height: 8),
          Text(
            context.l10n.phoneGateShortNote,
            style: context.texts.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
