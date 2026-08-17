import 'package:flutter_test/flutter_test.dart';
import 'package:wave/features/reviews/domain/entities/review.dart';

void main() {
  group('Review edit window (§4)', () {
    final created = DateTime(2026, 8, 4, 12);
    final review = Review(
      id: 'r1',
      productId: 'p1',
      orderId: 'o1',
      authorId: 'u1',
      rating: 5,
      createdAt: created,
    );

    test('editable immediately after submission', () {
      expect(review.isEditableAt(created), isTrue);
    });

    test('still editable at 47 hours', () {
      expect(
        review.isEditableAt(created.add(const Duration(hours: 47))),
        isTrue,
      );
    });

    test('locked at exactly 48 hours', () {
      // Long enough to fix a typo or change your mind after using the item;
      // short enough that a seller cannot pressure a rewrite months later.
      expect(
        review.isEditableAt(created.add(const Duration(hours: 48))),
        isFalse,
      );
    });

    test('locked well after the window', () {
      expect(
        review.isEditableAt(created.add(const Duration(days: 30))),
        isFalse,
      );
    });
  });
}
