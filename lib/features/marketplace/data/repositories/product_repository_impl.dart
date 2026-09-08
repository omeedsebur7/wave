import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:wave/core/error/failures.dart';
import 'package:wave/core/utils/result.dart';
import 'package:wave/features/marketplace/data/models/product_dto.dart';
import 'package:wave/features/marketplace/domain/entities/product.dart';
import 'package:wave/features/marketplace/domain/repositories/product_repository.dart';


class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(this._db, this._auth);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection('products');

  @override
  Future<Result<ProductPage>> browse({
    Object? cursor,
    int limit = 20,
    ProductSort sort = ProductSort.newest,
    String? category,
  }) async {
    try {
      var q = _products.where('status', isEqualTo: 'active');

      if (category != null) {
        q = q.where('category', isEqualTo: category);
      }

      q = switch (sort) {
        ProductSort.newest => q.orderBy('created_at', descending: true),
        ProductSort.priceLowToHigh => q.orderBy('price_minor'),
        ProductSort.priceHighToLow => q.orderBy('price_minor', descending: true),
        ProductSort.topRated => q.orderBy('rating_avg', descending: true),
      };

      q = q.limit(limit + 1); // one extra to detect hasMore
      if (cursor != null) {
        q = q.startAfterDocument(
          cursor as DocumentSnapshot<Map<String, dynamic>>,
        );
      }

      final snap = await q.get();
      final hasMore = snap.docs.length > limit;
      final docs = hasMore ? snap.docs.sublist(0, limit) : snap.docs;

      return Success(
        ProductPage(
          products: [for (final d in docs) ProductDto.fromDoc(d).toDomain()],
          cursor: docs.isEmpty ? null : docs.last,
          hasMore: hasMore,
        ),
      );
    } on FirebaseException catch (e) {
      return Err(
        ServerFailure(
          e.message ?? 'Could not load products',
          code: e.code,
          reason: FailureReason.productsLoadFailed,
        ),
      );
    } catch (_) {
      return const Err(NetworkFailure());
    }
  }

  @override
  Future<Result<Product>> byId(String productId) async {
    try {
      final doc = await _products.doc(productId).get();
      if (!doc.exists) {
        return const Err(
          NotFoundFailure('Product not found', FailureReason.productNotFound),
        );
      }
      return Success(ProductDto.fromDoc(doc).toDomain());
    } on FirebaseException catch (e) {
      return Err(ServerFailure(e.message ?? 'Error', code: e.code));
    } catch (_) {
      // ڕێگری لە کڕاشکردن ئەگەر داتاکە تێکچووبێت
      return const Err(NetworkFailure());
    }
  }

  @override
  Future<Result<List<Product>>> search(String query, {int limit = 20}) async {
    final term = query.trim().toLowerCase();
    if (term.isEmpty) return const Success([]);

    try {
      final snap = await _products
          .where('status', isEqualTo: 'active')
          .orderBy('title_lower')
          .startAt([term])
          .endAt(['$term\uf8ff'])
          .limit(limit)
          .get();

      return Success(
        [for (final d in snap.docs) ProductDto.fromDoc(d).toDomain()],
      );
    } on FirebaseException catch (e) {
      return Err(
        ServerFailure(
          e.message ?? 'Search failed',
          code: e.code,
          reason: FailureReason.searchFailed,
        ),
      );
    } catch (_) {
      return const Err(NetworkFailure());
    }
  }

  @override
  Future<Result<List<Product>>> bySeller(String sellerId, {int limit = 30}) async {
    try {
      final snap = await _products
          .where('seller_id', isEqualTo: sellerId)
          .where('status', isEqualTo: 'active')
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();
      return Success(
        [for (final d in snap.docs) ProductDto.fromDoc(d).toDomain()],
      );
    } on FirebaseException catch (e) {
      return Err(ServerFailure(e.message ?? 'Error', code: e.code));
    } catch (_) {
      return const Err(NetworkFailure());
    }
  }

  @override
  Future<Result<void>> toggleFavourite(
    String productId, {
    required bool saved,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const Err(
        AuthFailure(
          'Sign in to save products',
          reason: FailureReason.signInToSaveProducts,
        ),
      );
    }

    final ref = _db
        .collection('users')
        .doc(uid)
        .collection('favourites')
        .doc(productId);
    try {
      if (saved) {
        await ref.set({'created_at': FieldValue.serverTimestamp()});
      } else {
        await ref.delete();
      }
      return const Success(null);
    } on FirebaseException catch (e) {
      return Err(ServerFailure(e.message ?? 'Error', code: e.code));
    } catch (_) {
      return const Err(NetworkFailure());
    }
  }

  @override
  Future<Result<Set<String>>> favouriteIds() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Success({});
    try {
      final snap = await _db
          .collection('users')
          .doc(uid)
          .collection('favourites')
          .get();
      return Success({for (final d in snap.docs) d.id});
    } on FirebaseException catch (e) {
      return Err(ServerFailure(e.message ?? 'Error', code: e.code));
    } catch (_) {
      return const Err(NetworkFailure());
    }
  }
}
