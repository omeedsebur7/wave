import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:wave/core/error/failures.dart';
import 'package:wave/core/utils/result.dart';

/// Creates a marketplace listing (§4).
///
/// Images go to Cloud Storage; only video goes to Bunny (§6). Uploaded first
/// and in parallel, then the document is written once — a product document
/// referencing images that failed to upload renders as a grid of broken tiles,
/// which is worse than a listing that failed cleanly.
class ProductPublishService {
  ProductPublishService(this._db, this._storage, this._auth);

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  static const maxImages = 6;
  static const maxImageBytes = 10 * 1024 * 1024;

  Future<Result<String>> publish({
    required String title,
    required String description,
    required int priceMinor,
    required String currency,
    required int stock,
    required List<File> images,
    String? category,
    void Function(double)? onProgress,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return const Err(
        AuthFailure('Sign in to sell', reason: FailureReason.signInToSell),
      );
    }
    if (user.isAnonymous) {
      return const Err(
        PermissionFailure(
          'Guests cannot list products',
          FailureReason.guestCannotSell,
        ),
      );
    }

    if (title.trim().isEmpty) {
      return const Err(
        ServerFailure(
          'Give the item a name',
          reason: FailureReason.titleRequired,
        ),
      );
    }
    if (priceMinor <= 0) {
      return const Err(
        ServerFailure(
          'Set a price above zero',
          reason: FailureReason.priceRequired,
        ),
      );
    }
    if (images.isEmpty) {
      // A listing without a photo does not sell, and every image-less listing
      // in the grid makes the whole marketplace look abandoned.
      return const Err(
        ServerFailure(
          'Add at least one photo',
          reason: FailureReason.photoRequired,
        ),
      );
    }
    if (images.length > maxImages) {
      // The limit travels on the failure so the translated sentence can quote
      // it without `core` needing to import this service.
      return const Err(
        ServerFailure(
          'Too many photos',
          reason: FailureReason.tooManyPhotos,
          limit: maxImages,
        ),
      );
    }

    for (final image in images) {
      if (await image.length() > maxImageBytes) {
        return const Err(
          ServerFailure(
            'Image exceeds maxImageBytes',
            reason: FailureReason.photoTooLarge,
            limit: maxImageBytes ~/ (1024 * 1024),
          ),
        );
      }
    }

    try {
      final productRef = _db.collection('products').doc();
      var uploaded = 0;

      // Parallel, because six sequential uploads on a mobile connection is a
      // minute of staring at a progress bar.
      final urls = await Future.wait(
        images.asMap().entries.map((entry) async {
          final ref = _storage
              .ref('products/${user.uid}/${productRef.id}_${entry.key}.jpg');
          await ref.putFile(
            entry.value,
            SettableMetadata(contentType: 'image/jpeg'),
          );
          uploaded += 1;
          onProgress?.call(uploaded / images.length);
          return ref.getDownloadURL();
        }),
      );

      await productRef.set({
        'seller_id': user.uid,
        'seller_name': user.displayName ?? '',
        'title': title.trim(),
        // Lowercased copy powering prefix search (§4). Written here because
        // Firestore has no case-insensitive query operator.
        'title_lower': title.trim().toLowerCase(),
        'description': description.trim(),
        'price_minor': priceMinor,
        'currency': currency,
        'stock': stock,
        'image_urls': urls,
        'image_url': urls.first,
        if (category != null) 'category': category,
        'status': 'active',
        // Aggregates start at zero and are only ever written by functions
        // afterwards — Security Rules reject any client attempt to set them.
        'rating_avg': 0,
        'rating_count': 0,
        'sold_count': 0,
        'created_at': FieldValue.serverTimestamp(),
      });

      return Success(productRef.id);
    } on FirebaseException catch (e) {
      return Err(
        ServerFailure(
          e.message ?? 'Could not publish the listing',
          code: e.code,
          reason: FailureReason.publishFailed,
        ),
      );
    }
  }
}
