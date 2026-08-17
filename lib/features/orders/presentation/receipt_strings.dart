import 'package:flutter/widgets.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/utils/dates.dart';
import 'package:wave/features/orders/data/receipt_service.dart';
import 'package:wave/features/orders/domain/entities/order.dart';

/// Builds [ReceiptStrings] from the current locale.
///
/// Lives in presentation because that is the only layer with a BuildContext.
/// The receipt is generated in whatever language the person is reading — which
/// matters more here than on screen, since a receipt is a document they may
/// hand to someone else.
ReceiptStrings receiptStringsFor(BuildContext context, Order order) {
  final shortId = '#${order.id.substring(0, order.id.length < 6 ? order.id.length : 6).toUpperCase()}';

  return ReceiptStrings(
    brand: context.l10n.appName,
    documentTitle: context.l10n.receiptDocTitle(shortId),
    receipt: context.l10n.receiptTitle,
    orderLabel: context.l10n.orderNumber(shortId),
    soldBy: context.l10n.receiptSoldBy,
    buyer: context.l10n.receiptBuyer,
    deliveredTo: context.l10n.receiptDeliveredTo,
    status: context.l10n.receiptStatus,
    item: context.l10n.receiptItem,
    qty: context.l10n.receiptQty,
    unit: context.l10n.receiptUnit,
    total: context.l10n.total,
    disclaimer: context.l10n.receiptDisclaimer,
    orderedOnDate: Dates.short(context, order.createdAt),
    statusLabels: {
      CustomerOrderStage.confirmed: context.l10n.orderConfirmed,
      CustomerOrderStage.onTheWay: context.l10n.orderOnTheWay,
      CustomerOrderStage.delivered: context.l10n.orderDelivered,
      CustomerOrderStage.cancelled: context.l10n.orderCancelled,
    },
  );
}
