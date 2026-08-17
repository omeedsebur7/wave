import 'package:wave/core/utils/result.dart';
import 'package:wave/features/marketplace/domain/entities/product.dart';

abstract class ProductRepository {
  Future<Result<ProductPage>> browse({
    Object? cursor,
    int limit,
    ProductSort sort,
    String? category,
  });

  Future<Result<Product>> byId(String productId);

  /// Launch search is straightforward Firestore queries (§4). That means
  /// prefix matching only — no fuzzy matching, no typo tolerance, no relevance
  /// ranking. It's genuinely limited, and it's the right call until query
  /// volume justifies an Algolia index in P2.
  Future<Result<List<Product>>> search(String query, {int limit});

  Future<Result<List<Product>>> bySeller(String sellerId, {int limit});

  Future<Result<void>> toggleFavourite(String productId, {required bool saved});
  Future<Result<Set<String>>> favouriteIds();
}
