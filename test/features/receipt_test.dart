import 'package:flutter_test/flutter_test.dart';
import 'package:wave/features/orders/data/receipt_service.dart';
import 'package:wave/features/orders/domain/entities/order.dart';

/// Fixed English strings. The point of injecting them is that the service does
/// not depend on a locale — so the test supplies its own and stays independent
/// of the ARB files.
const _strings = ReceiptStrings(
  brand: 'WAVE',
  documentTitle: 'WAVE receipt #ABC123',
  receipt: 'Receipt',
  orderLabel: 'Order #ABC123',
  soldBy: 'Sold by',
  buyer: 'Buyer',
  deliveredTo: 'Delivered to',
  status: 'Status',
  item: 'Item',
  qty: 'Qty',
  unit: 'Unit',
  total: 'Total',
  disclaimer: 'Not a tax invoice.',
  orderedOnDate: '14/03/2026',
  statusLabels: {
    CustomerOrderStage.confirmed: 'Confirmed',
    CustomerOrderStage.onTheWay: 'On the way',
    CustomerOrderStage.delivered: 'Delivered',
    CustomerOrderStage.cancelled: 'Cancelled',
  },
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final order = Order(
    id: 'abc123def456',
    buyerId: 'b1',
    sellerId: 's1',
    items: const [
      OrderItem(
        productId: 'p1',
        title: 'Handmade leather bag',
        unitPriceMinor: 45000,
        quantity: 2,
        imageUrl: '',
      ),
    ],
    totalMinor: 90000,
    currency: 'IQD',
    internalStatus: OrderInternalStatus.delivered,
    createdAt: DateTime(2026, 8, 4),
    idempotencyKey: 'key-123',
  );

  group('Receipt generation', () {
    test('produces a non-empty PDF', () async {
      final bytes = await const ReceiptService()
          .generate(order: order, sellerName: 'A Seller', strings: _strings);
      expect(bytes, isNotEmpty);
      // %PDF- magic bytes.
      expect(bytes.sublist(0, 5), [0x25, 0x50, 0x44, 0x46, 0x2D]);
    });

    test('handles an order with no items without throwing', () async {
      final empty = Order(
        id: 'x', buyerId: 'b', sellerId: 's', items: const [],
        totalMinor: 0, currency: 'IQD',
        internalStatus: OrderInternalStatus.cancelled,
        createdAt: DateTime(2026), idempotencyKey: 'k',
      );
      final bytes = await const ReceiptService()
          .generate(order: empty, sellerName: 'Seller', strings: _strings);
      expect(bytes, isNotEmpty);
    });

    test('a short order id does not overflow the substring', () async {
      // Guards the `#ABC123` shortening against ids shorter than 6 characters,
      // which is exactly the kind of thing that only breaks in production.
      final short = Order(
        id: 'ab', buyerId: 'b', sellerId: 's', items: const [],
        totalMinor: 0, currency: 'IQD',
        internalStatus: OrderInternalStatus.confirmed,
        createdAt: DateTime(2026), idempotencyKey: 'k',
      );
      await expectLater(
        const ReceiptService()
            .generate(order: short, sellerName: 'S', strings: _strings),
        completes,
      );
    });
  });
}
