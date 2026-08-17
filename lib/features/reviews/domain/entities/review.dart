import 'package:equatable/equatable.dart';

/// Product review — Verified Purchase only (§4).
///
/// The gate isn't "has an account", it's "has a DELIVERED order containing this
/// exact product". One review per order, editable for 48 hours, then locked.
/// That window is long enough to fix a typo or change your mind after using the
/// item, short enough that a seller can't pressure someone into rewriting a
/// review months later.
class Review extends Equatable {
  const Review({
    required this.id,
    required this.productId,
    required this.orderId,
    required this.authorId,
    required this.rating,
    required this.createdAt,
    this.text,
    this.editedAt,
  });

  final String id;
  final String productId;

  /// The proof-of-purchase link. Security Rules verify this order exists, is
  /// delivered, belongs to the author, and contains this product.
  final String orderId;

  final String authorId;

  /// 1–5.
  final int rating;
  final String? text;
  final DateTime createdAt;
  final DateTime? editedAt;

  static const editWindow = Duration(hours: 48);

  bool isEditableAt(DateTime now) =>
      now.difference(createdAt) < editWindow;

  @override
  List<Object?> get props => [id, rating, text, editedAt];
}

/// Seller rating — the input to the trust-tier system (§5.2 / §3.7).
/// Separate from a product review: you can love the item and still have been
/// let down by how it was sent.
class SellerRating extends Equatable {
  const SellerRating({
    required this.id,
    required this.sellerId,
    required this.orderId,
    required this.authorId,
    required this.rating,
    required this.createdAt,
    this.text,
  });

  final String id;
  final String sellerId;
  final String orderId;
  final String authorId;
  final int rating;
  final String? text;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, sellerId, orderId, rating];
}
