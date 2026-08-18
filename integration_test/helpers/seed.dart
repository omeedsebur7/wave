import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:wave/core/config/emulator.dart';

/// Emulator seeding for integration tests.
///
/// Normal application flows use the Firebase client SDK and therefore go
/// through the same Security Rules as the real application.
///
/// Emulator-only fixture helpers use the local emulator REST API for states
/// that a real client is deliberately not allowed to create.
///
/// These helpers are protected by USE_EMULATOR=true.
class TestSeed {
  TestSeed(this._db, this._auth);

  factory TestSeed.instance() {
    return TestSeed(
      FirebaseFirestore.instance,
      FirebaseAuth.instance,
    );
  }

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  static const _emulatorHost = String.fromEnvironment(
    'EMULATOR_HOST',
    defaultValue: 'localhost',
  );

  static const _useEmulator = bool.fromEnvironment(
    'USE_EMULATOR',
  );

  static const _testPassword = 'WaveTest!123456';

  static String _email(String role) {
    return '$role-${DateTime.now().microsecondsSinceEpoch}@wave.test';
  }

  void _requireEmulator() {
    if (!_useEmulator) {
      throw StateError(
        'This helper is emulator-only. Run with '
        '--dart-define=USE_EMULATOR=true',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // AUTH / USERS
  // ---------------------------------------------------------------------------

  Future<String> _signInRealUser({
    required String role,
    required String displayName,
  }) async {
    await _auth.signOut();

    final credential = await _auth.createUserWithEmailAndPassword(
      email: _email(role),
      password: _testPassword,
    );

    final uid = credential.user!.uid;

    await _db.collection('users').doc(uid).set({
      'display_name': displayName,
      'created_at': FieldValue.serverTimestamp(),
    });

    return uid;
  }

  /// A real, non-anonymous buyer with a fixed address id: addr_1.
  ///
  /// Does NOT mark the phone verified — that is a separate, explicit step.
  ///
  /// It used to. The consequence was that "an unverified buyer is refused
  /// before any charge" could no longer fail: the helper quietly verified
  /// every buyer it created, so the test sailed through the gate it exists to
  /// prove, and the error it eventually reported came from somewhere else
  /// entirely. A fixture that grants the exact permission a test is trying to
  /// withhold is worse than no fixture.
  Future<String> signInReadyBuyer({
    String phone = '+9647700000001',
  }) async {
    await _auth.signOut();

    final credential = await _auth.createUserWithEmailAndPassword(
      email: _email('buyer'),
      password: _testPassword,
    );

    final uid = credential.user!.uid;

    await _db.collection('users').doc(uid).set({
      'display_name': 'Test Buyer',
      'phone_number': phone,
      'created_at': FieldValue.serverTimestamp(),
    });

    // placeOrder() sends addressId: addr_1.
    await _adminCreateDocument(
      'users/$uid/addresses/addr_1',
      {
        'recipient_name': {'stringValue': 'Test Buyer'},
        'phone_number': {'stringValue': phone},
        'city': {'stringValue': 'Erbil'},
        'address_line': {'stringValue': '100 Test Street'},
        'is_default': {'booleanValue': true},
        'created_at': {
          'timestampValue': DateTime.now().toUtc().toIso8601String(),
        },
      },
    );

    return uid;
  }

  Future<String> signInGuest() async {
    await _auth.signOut();

    final credential = await _auth.signInAnonymously();

    return credential.user!.uid;
  }

  Future<String> seedSeller({
    String name = 'Test Seller',
    int completedOrders = 0,
    double avgRating = 0,
    String tier = 'newSeller',
  }) async {
    await _auth.signOut();

    final credential = await _auth.createUserWithEmailAndPassword(
      email: _email('seller'),
      password: _testPassword,
    );

    final uid = credential.user!.uid;

    await _db.collection('users').doc(uid).set({
      'display_name': name,
      'completed_orders': completedOrders,
      'avg_rating': avgRating,
      'trust_tier': tier,
      'created_at': FieldValue.serverTimestamp(),
    });

    return uid;
  }

  Future<String> signInAsSeller() async {
    return _signInRealUser(
      role: 'seller-status',
      displayName: 'Test Seller',
    );
  }

  // ---------------------------------------------------------------------------
  // PRODUCTS
  // ---------------------------------------------------------------------------

  Future<String> seedProduct({
    required String sellerId,
    String title = 'Test Product',
    int priceMinor = 25000,
    int stock = 10,
    String currency = 'IQD',
  }) async {
    _requireEmulator();

    final ref = _db.collection('products').doc();

    await _adminCreateDocument(
      'products/${ref.id}',
      {
        'seller_id': {'stringValue': sellerId},
        'seller_name': {'stringValue': 'Test Seller'},
        'title': {'stringValue': title},
        'title_lower': {
          'stringValue': title.toLowerCase(),
        },
        'description': {
          'stringValue': 'Seeded for tests',
        },
        'price_minor': {
          'integerValue': '$priceMinor',
        },
        'currency': {
          'stringValue': currency,
        },
        'image_urls': {
          'arrayValue': {
            'values': <Map<String, dynamic>>[],
          },
        },
        // placeOrder reads `image_url` (singular) for the order line item.
        // ProductPublishService writes both; a fixture with only the array
        // leaves every seeded order carrying an empty image.
        'image_url': {'stringValue': ''},
        'stock': {
          'integerValue': '$stock',
        },
        'status': {
          'stringValue': 'active',
        },
        // Aggregates the app always creates at zero. A product without them
        // is a shape production can never produce.
        'rating_avg': {'integerValue': '0'},
        'rating_count': {'integerValue': '0'},
        'sold_count': {'integerValue': '0'},
        'created_at': {
          'timestampValue': DateTime.now().toUtc().toIso8601String(),
        },
      },
    );

    return ref.id;
  }

  // ---------------------------------------------------------------------------
  // REELS
  // ---------------------------------------------------------------------------

  /// Seeds a Reel through emulator REST.
  ///
  /// The test usually has the buyer authenticated when this method is called,
  /// while authorId belongs to the seller. Therefore a client write would be
  /// rejected by the Reels rules.
  Future<String> seedReel({
    required String authorId,
    String? linkedProductId,
    String caption = 'Test reel',
    int durationSeconds = 30,
  }) async {
    _requireEmulator();

    final ref = _db.collection('reels').doc();

    await _adminCreateDocument(
      'reels/${ref.id}',
      {
        'author_id': {
          'stringValue': authorId,
        },
        'author_name': {
          'stringValue': 'Test Seller',
        },
        'bunny_video_id': {
          'stringValue': 'test-video-${ref.id}',
        },
        'thumbnail_url': {
          'stringValue': 'https://example.test/thumb.jpg',
        },
        'caption': {
          'stringValue': caption,
        },
        'caption_lower': {
          'stringValue': caption.toLowerCase(),
        },
        'duration_seconds': {
          'integerValue': '$durationSeconds',
        },
        'linked_product_id': linkedProductId == null
            ? {'nullValue': null}
            : {'stringValue': linkedProductId},
        'status': {
          'stringValue': 'published',
        },
        'likes_count': {
          'integerValue': '0',
        },
        'views_count': {
          'integerValue': '0',
        },
        'comments_count': {
          'integerValue': '0',
        },
        'rank_score': {
          'integerValue': '0',
        },
        'created_at': {
          'timestampValue': DateTime.now().toUtc().toIso8601String(),
        },
      },
    );

    return ref.id;
  }

  Future<List<String>> seedFeed({
    required String authorId,
    int count = 50,
  }) {
    return Future.wait([
      for (var i = 0; i < count; i++)
        seedReel(
          authorId: authorId,
          caption: 'Reel number $i',
        ),
    ]);
  }

  Future<int> reelCountFor(String authorId) async {
    final snapshot = await _db
        .collection('reels')
        .where(
          'author_id',
          isEqualTo: authorId,
        )
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  Future<Map<String, dynamic>?> reel(String reelId) async {
    return (await _db.collection('reels').doc(reelId).get()).data();
  }

  Future<void> setReelProductLink(
    String reelId,
    String productId,
  ) {
    return _db.collection('reels').doc(reelId).update({
      'linked_product_id': productId,
    });
  }

  // ---------------------------------------------------------------------------
  // PHONE VERIFICATION
  // ---------------------------------------------------------------------------

  /// Flips phone_verified through the emulator's rules-bypassing REST API.
  ///
  /// [phone] is a parameter rather than a constant because writing one
  /// hardcoded number over whatever the account actually holds is how a second
  /// buyer silently ends up sharing the first buyer's phone number.
  Future<void> markPhoneVerified(
    String uid, {
    String phone = '+9647700000001',
  }) async {
    await _adminPatch(
      'users/$uid',
      {
        'phone_verified': {'booleanValue': true},
        'phone_number': {'stringValue': phone},
      },
    );
  }

  // ---------------------------------------------------------------------------
  // ORDERS
  // ---------------------------------------------------------------------------

  /// Calls the real placeOrder Cloud Function.
  ///
  /// The generated key is deliberately long: placeOrder rejects anything under
  /// 8 characters with "Missing idempotency key", and a short literal in a
  /// test reads as a wiring failure rather than as a length check.
  Future<Map<String, dynamic>?> placeOrder({
    required String productId,
    required int quantity,
    String? idempotencyKey,
    String? sourceReelId,
    String? promoCode,
    int? claimedTotalMinor,
    String paymentMethodId = 'cash_on_delivery',
  }) async {
    final key =
        idempotencyKey ?? 'test-${DateTime.now().microsecondsSinceEpoch}';

    if (key.trim().length < 8) {
      throw ArgumentError.value(
        idempotencyKey,
        'idempotencyKey',
        'placeOrder requires at least 8 characters; the server rejects '
            'anything shorter as a missing key',
      );
    }

    final result = await FirebaseFunctions.instance
        .httpsCallable('placeOrder')
        .call<Map<String, dynamic>>({
      'idempotencyKey': key,
      'items': [
        {
          'productId': productId,
          'quantity': quantity,
        },
      ],
      'addressId': 'addr_1',
      'paymentMethodId': paymentMethodId,
      if (sourceReelId != null)
        'sourceReelId': sourceReelId,
      if (promoCode != null)
        'promoCode': promoCode,
      if (claimedTotalMinor != null)
        'totalMinor': claimedTotalMinor,
    });

    return result.data;
  }

  Future<String> seedConfirmedOrder({
    required String sellerId,
    required String productId,
    String? buyerId,
  }) async {
    final resolvedBuyerId = buyerId ?? _auth.currentUser?.uid;

    if (resolvedBuyerId == null) {
      throw StateError(
        'seedConfirmedOrder requires a buyerId '
        'or an authenticated buyer.',
      );
    }

    return _adminCreateOrder(
      buyerId: resolvedBuyerId,
      sellerId: sellerId,
      productId: productId,
      totalMinor: 25000,
      status: 'confirmed',
    );
  }

  Future<String> seedDeliveredOrder({
    required String buyerId,
    required String sellerId,
    required String productId,
    int totalMinor = 25000,
  }) async {
    final orderId = await _adminCreateOrder(
      buyerId: buyerId,
      sellerId: sellerId,
      productId: productId,
      totalMinor: totalMinor,
      status: 'confirmed',
    );

    for (final status in [
      'packed',
      'handedToCourier',
      'delivered',
    ]) {
      await _adminPatch(
        'orders/$orderId',
        {
          'status': {'stringValue': status},
          if (status == 'delivered')
            'delivered_at': {
              'timestampValue':
                  DateTime.now().toUtc().toIso8601String(),
            },
        },
      );
    }

    return orderId;
  }

  Future<void> setOrderStatus(
    String orderId,
    String status,
  ) {
    return _db.collection('orders').doc(orderId).update({
      'status': status,
    });
  }

  Future<void> forceStatus(
    String orderId,
    String status,
  ) {
    return _adminPatch(
      'orders/$orderId',
      {
        'status': {'stringValue': status},
      },
    );
  }

  Future<void> cancelAsBuyer(String orderId) {
    return _db.collection('orders').doc(orderId).update({
      'status': 'cancelled',
      'cancelled_by': 'buyer',
      'cancelled_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> order(String orderId) async {
    return (await _db.collection('orders').doc(orderId).get()).data();
  }

  Future<int> orderCount() {
    return _adminCollectionCount('orders');
  }

  Future<int> stockOf(String productId) async {
    final snapshot = await _db
        .collection('products')
        .doc(productId)
        .get();

    return (snapshot.data()?['stock'] as num?)?.toInt() ?? 0;
  }

  /// Rates a seller AS THE CURRENTLY SIGNED-IN USER.
  ///
  /// Pass [expectedAuthorId]. Every seedSeller and signInReadyBuyer call signs
  /// the previous identity out, so which account is active here depends on the
  /// order of the lines above rather than on anything stated. When that drifts,
  /// Security Rules reject the write and the failure reads `permission-denied`
  /// — which looks like a rules bug instead of "the wrong person is signed in".
  /// This turns that into a sentence.
  Future<void> submitSellerRating({
    required String orderId,
    required String sellerId,
    required int rating,
    String? expectedAuthorId,
  }) async {
    final authorId = _auth.currentUser?.uid;

    if (authorId == null) {
      throw StateError(
        'submitSellerRating needs a signed-in user; nobody is authenticated.',
      );
    }

    if (expectedAuthorId != null && authorId != expectedAuthorId) {
      throw StateError(
        'submitSellerRating would write as $authorId, but the test expected '
        '$expectedAuthorId. A later seedSeller/signIn call replaced the '
        "session — the rating must be submitted by the order's buyer.",
      );
    }

    await _db.collection('seller_ratings').doc(orderId).set({
      'seller_id': sellerId,
      'order_id': orderId,
      'author_id': authorId,
      'rating': rating,
      'created_at': FieldValue.serverTimestamp(),
    });

    // Emulator REST, not a client write.
    //
    // The orders rule permits the buyer exactly one update: status ->
    // 'cancelled', with affectedKeys().hasOnly(['status', 'cancelled_at',
    // 'cancelled_by', 'updated_at']). `has_been_rated` is not in that list and
    // never will be — it is a function-owned flag, materialised by
    // notifyNewRating / onReviewWritten, precisely so a buyer cannot clear it
    // and rate the same order twice. A client write here is denied by design,
    // and the resulting `permission-denied` reads as a rules bug rather than as
    // the rule working.
    //
    // In production the trigger sets this. The trigger cannot be relied on in
    // an integration test that asserts on the flag immediately afterwards, so
    // the fixture writes it directly.
    await _adminPatch(
      'orders/$orderId',
      {
        'has_been_rated': {'booleanValue': true},
      },
    );
  }

  // ---------------------------------------------------------------------------
  // REPORTS
  // ---------------------------------------------------------------------------

  /// Attempts a report read AS THE CURRENT (non-moderator) USER.
  ///
  /// Exists only to assert the refusal. Named so that no future caller mistakes
  /// it for a fixture read — it is expected to throw permission-denied, and a
  /// test using it to fetch a report will fail in a confusing way.
  Future<Map<String, dynamic>?> reportAsCurrentUser(String reportId) async {
    return (await _db.collection('reports').doc(reportId).get()).data();
  }

  // getReport deliberately does not live here.
  //
  // `reports` is readable only by a moderator (see firestore.rules), and
  // TestSeed's own session is a plain buyer or seller by design — the same
  // reason moderationLogCount is a method on SecondModerator. A client read
  // from here is refused by the rule that stops ordinary users browsing other
  // people's reports, which is the rule working.
  //
  // The read is therefore SecondModerator.report(). Reading through the
  // identity that just wrote is also closer to what the app does, and keeps the
  // read exercising the rule rather than bypassing it over REST.

  /// Seeds a pending report through emulator REST.
  ///
  /// Deliberately NOT a client write. The reports create rule requires
  /// `reporter_id == request.auth.uid` and `cooledDown('last_report_at', 30)`,
  /// and this fixture supplies a synthetic reporter id belonging to no real
  /// account — so as a client write it is denied, correctly, by the rule that
  /// stops one person filing reports as another.
  ///
  /// Mirrored from ModerationRepository.fileReport field-for-field rather than
  /// approximated: resolveReport's transaction reads `action` and branches on
  /// the literal string 'pending', so a seed with a different shape would test
  /// a report that could never exist.
  Future<String> seedReport({
    required String targetId,
    String targetType = 'reel',
    String reporterId = 'reporter_1',
  }) async {
    final ref = _db.collection('reports').doc();

    await _adminCreateDocument(
      'reports/${ref.id}',
      {
        'target_type': {'stringValue': targetType},
        'target_id': {'stringValue': targetId},
        'reason': {'stringValue': 'spam'},
        'reporter_id': {'stringValue': reporterId},
        'action': {'stringValue': 'pending'},
        'report_count': {'integerValue': '1'},
        'created_at': {
          'timestampValue': DateTime.now().toUtc().toIso8601String(),
        },
      },
    );

    return ref.id;
  }

  // ---------------------------------------------------------------------------
  // BUNNY / REELS FUNCTIONS
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> requestUploadSlot({
    required int durationSeconds,
  }) async {
    final result = await FirebaseFunctions.instance
        .httpsCallable('createBunnyUploadSlot')
        .call<Map<String, dynamic>>({
      'title': 'Test reel',
      'durationSeconds': durationSeconds,
    });

    return result.data;
  }

  Future<String> publishReel({
    required String bunnyVideoId,
    required int durationSeconds,
    String caption = 'Test reel',
    String? linkedProductId,
  }) async {
    final result = await FirebaseFunctions.instance
        .httpsCallable('publishReel')
        .call<Map<String, dynamic>>({
      'bunnyVideoId': bunnyVideoId,
      'caption': caption,
      'durationSeconds': durationSeconds,
      'linkedProductId': linkedProductId,
    });

    return result.data['reelId'] as String;
  }

  // ---------------------------------------------------------------------------
  // FIRESTORE EMULATOR REST HELPERS
  // ---------------------------------------------------------------------------

  /// One place the REST document URL is built.
  ///
  /// It was five, and one of them had `/v1/projects=$project` instead of
  /// `/v1/projects/$project` — a single character that 404'd every
  /// markPhoneVerified and read like a rules or connectivity failure.
  static String _documentsUrl(String projectId, String path) =>
      'http://$_emulatorHost:${EmulatorConfig.firestorePort}'
      '/v1/projects/$projectId'
      '/databases/(default)/documents/$path';

  Future<void> _adminCreateDocument(
    String path,
    Map<String, dynamic> fields,
  ) async {
    _requireEmulator();

    final projectId = Firebase.app().options.projectId;

    final response = await http.patch(
      Uri.parse(_documentsUrl(projectId, path)),
      headers: const {
        'Authorization': 'Bearer owner',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fields': fields,
      }),
    );

    if (response.statusCode >= 300) {
      throw StateError(
        'Failed to create emulator document "$path": '
        '${response.statusCode} ${response.body}',
      );
    }
  }

  Future<void> _adminPatch(
    String path,
    Map<String, dynamic> fields,
  ) async {
    _requireEmulator();

    final project = Firebase.app().options.projectId;

    final mask = fields.keys
        .map(
          (key) => 'updateMask.fieldPaths=$key',
        )
        .join('&');

    final response = await http.patch(
      Uri.parse('${_documentsUrl(project, path)}?$mask'),
      headers: const {
        'Authorization': 'Bearer owner',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fields': fields,
      }),
    );

    if (response.statusCode >= 300) {
      throw StateError(
        'Emulator patch failed: '
        '${response.statusCode} ${response.body}',
      );
    }
  }

  Future<String> _adminCreateOrder({
    required String buyerId,
    required String sellerId,
    required String productId,
    required int totalMinor,
    required String status,
  }) async {
    _requireEmulator();

    final ref = _db.collection('orders').doc();

    await _adminCreateDocument(
      'orders/${ref.id}',
      {
        // placeOrder writes `id` onto the document; anything reading an order
        // by its own field rather than its path needs it present here too.
        'id': {'stringValue': ref.id},
        'buyer_id': {
          'stringValue': buyerId,
        },
        'seller_id': {
          'stringValue': sellerId,
        },
        'items': {
          'arrayValue': {
            'values': [
              {
                'mapValue': {
                  'fields': {
                    'product_id': {
                      'stringValue': productId,
                    },
                    'title': {
                      'stringValue': 'Test Product',
                    },
                    'unit_price_minor': {
                      'integerValue': '$totalMinor',
                    },
                    'quantity': {
                      'integerValue': '1',
                    },
                    'image_url': {
                      'stringValue': '',
                    },
                  },
                },
              },
            ],
          },
        },
        'product_ids': {
          'arrayValue': {
            'values': [
              {
                'stringValue': productId,
              },
            ],
          },
        },
        'subtotal_minor': {
          'integerValue': '$totalMinor',
        },
        'discount_minor': {
          'integerValue': '0',
        },
        'total_minor': {
          'integerValue': '$totalMinor',
        },
        'currency': {
          'stringValue': 'IQD',
        },
        'status': {
          'stringValue': status,
        },
        'payment_method_id': {
          'stringValue': 'cash_on_delivery',
        },
        'idempotency_key': {
          'stringValue': 'seed_${ref.id}',
        },
        'has_been_rated': {
          'booleanValue': false,
        },
        'created_at': {
          'timestampValue':
              DateTime.now().toUtc().toIso8601String(),
        },
      },
    );

    return ref.id;
  }

  Future<int> _adminCollectionCount(
    String collection,
  ) async {
    _requireEmulator();

    final project = Firebase.app().options.projectId;

    final response = await http.get(
      Uri.parse('${_documentsUrl(project, collection)}?pageSize=1000'),
      headers: const {
        'Authorization': 'Bearer owner',
      },
    );

    if (response.statusCode >= 300) {
      throw StateError(
        'Failed to count $collection: '
        '${response.statusCode} ${response.body}',
      );
    }

    final body = jsonDecode(response.body);

    if (body is! Map<String, dynamic>) {
      return 0;
    }

    final documents = body['documents'];

    if (documents is! List) {
      return 0;
    }

    // pageSize caps the response, so a collection larger than this reports the
    // cap as though it were the total — inside assertions about exactly how
    // many orders exist. Loud beats quietly wrong.
    if (documents.length >= 1000) {
      throw StateError(
        '$collection returned a full page of 1000 documents; the count is '
        'capped and no longer trustworthy. Paginate via nextPageToken if a '
        'test legitimately needs this many.',
      );
    }

    return documents.length;
  }

  Future<void> clearAll() async {
    _requireEmulator();

    final projectId = Firebase.app().options.projectId;

    final response = await http.delete(
      Uri.parse(
        'http://$_emulatorHost:${EmulatorConfig.firestorePort}'
        '/emulator/v1/projects/$projectId'
        '/databases/(default)/documents',
      ),
      headers: const {
        'Authorization': 'Bearer owner',
      },
    );

    if (response.statusCode >= 300) {
      throw StateError(
        'Failed to reset Firestore emulator: '
        '${response.statusCode} ${response.body}',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // SECOND IDENTITIES
  // ---------------------------------------------------------------------------

  /// Points a secondary FirebaseApp's SDKs at the same emulator suite.
  ///
  /// Shared, because three hand-written copies of the same host/port wiring is
  /// how one of them drifts from the other two.
  static Future<void> _useEmulators({
    required FirebaseAuth auth,
    required FirebaseFirestore db,
    required FirebaseFunctions functions,
  }) async {
    await auth.useAuthEmulator(_emulatorHost, EmulatorConfig.authPort);
    db.useFirestoreEmulator(_emulatorHost, EmulatorConfig.firestorePort);
    functions.useFunctionsEmulator(_emulatorHost, EmulatorConfig.functionsPort);
  }

  static Future<SecondBuyer> signInSecondBuyer({
    String phone = '+9647700000002',
  }) async {
    final app = await Firebase.initializeApp(
      name: 'second-buyer-${DateTime.now().microsecondsSinceEpoch}',
      options: Firebase.app().options,
    );

    final auth = FirebaseAuth.instanceFor(app: app);
    final db = FirebaseFirestore.instanceFor(app: app);
    final functions = FirebaseFunctions.instanceFor(app: app);

    await _useEmulators(auth: auth, db: db, functions: functions);

    final credential = await auth.createUserWithEmailAndPassword(
      email: _email('second-buyer'),
      password: _testPassword,
    );

    final uid = credential.user!.uid;

    await db.collection('users').doc(uid).set({
      'display_name': 'Second Test Buyer',
      'phone_number': phone,
      'created_at': FieldValue.serverTimestamp(),
    });

    final projectId = Firebase.app().options.projectId;

    final response = await http.patch(
      Uri.parse(
        _documentsUrl(projectId, 'users/$uid/addresses/addr_1'),
      ),
      headers: const {
        'Authorization': 'Bearer owner',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fields': {
          'recipient_name': {
            'stringValue': 'Second Test Buyer',
          },
          'phone_number': {
            'stringValue': phone,
          },
          'city': {
            'stringValue': 'Erbil',
          },
          'address_line': {
            'stringValue': '200 Test Street',
          },
          'is_default': {
            'booleanValue': true,
          },
          'created_at': {
            'timestampValue':
                DateTime.now().toUtc().toIso8601String(),
          },
        },
      }),
    );

    if (response.statusCode >= 300) {
      throw StateError(
        'Failed to create second buyer address: '
        '${response.statusCode} ${response.body}',
      );
    }

    return SecondBuyer(
      uid: uid,
      auth: auth,
      functions: functions,
      app: app,
    );
  }

  static Future<SecondModerator> signInSecondModerator() async {
    final app = await Firebase.initializeApp(
      name: 'second-moderator-${DateTime.now().microsecondsSinceEpoch}',
      options: Firebase.app().options,
    );

    final auth = FirebaseAuth.instanceFor(app: app);
    final functions = FirebaseFunctions.instanceFor(app: app);
    final db = FirebaseFirestore.instanceFor(app: app);

    await _useEmulators(auth: auth, db: db, functions: functions);

    final credential = await auth.createUserWithEmailAndPassword(
      email: _email('moderator'),
      password: _testPassword,
    );

    final uid = credential.user!.uid;
    final projectId = Firebase.app().options.projectId;

    final response = await http.post(
      Uri.parse(
        'http://$_emulatorHost:${EmulatorConfig.authPort}/'
        'identitytoolkit.googleapis.com/v1/projects/$projectId/'
        'accounts:update',
      ),
      headers: const {
        'Authorization': 'Bearer owner',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'localId': uid,
        'customAttributes': jsonEncode({
          'moderator': true,
        }),
      }),
    );

    if (response.statusCode >= 300) {
      throw StateError(
        'Could not grant moderator claim: '
        '${response.statusCode} ${response.body}',
      );
    }

    // The claim only reaches the client in a freshly minted token; the one
    // cached at sign-in predates it.
    await auth.currentUser!.getIdToken(true);

    return SecondModerator(
      uid: uid,
      auth: auth,
      functions: functions,
      db: db,
      app: app,
    );
  }
}

/// A second buyer's isolated identity for concurrency tests.
class SecondBuyer {
  const SecondBuyer({
    required this.uid,
    required this.auth,
    required this.functions,
    required this.app,
  });

  final String uid;
  final FirebaseAuth auth;
  final FirebaseFunctions functions;
  final FirebaseApp app;

  Future<Map<String, dynamic>?> placeOrder({
    required String productId,
    required int quantity,
  }) async {
    final result = await functions
        .httpsCallable('placeOrder')
        .call<Map<String, dynamic>>({
      'idempotencyKey':
          'second-buyer-${DateTime.now().microsecondsSinceEpoch}',
      'items': [
        {
          'productId': productId,
          'quantity': quantity,
        },
      ],
      'addressId': 'addr_1',
      'paymentMethodId': 'cash_on_delivery',
    });

    return result.data;
  }

  /// Releases the identity WITHOUT deleting the FirebaseApp.
  ///
  /// `app.delete()` was here and had to go. Deleting a secondary FirebaseApp
  /// tears down platform-channel state that the DEFAULT app's
  /// FirebaseFirestore.instance and FirebaseAuth.instance are still holding, so
  /// every subsequent test in the file died with
  /// `[cloud_firestore/unknown] FirebaseApp was deleted` — from inside
  /// seedSeller, which has nothing to do with this buyer. A teardown that
  /// breaks unrelated later tests is worse than a leaked app.
  ///
  /// Signing out is sufficient isolation: the identity can no longer act, and
  /// the test process exits moments later, so nothing accumulates.
  Future<void> dispose() async {
    await auth.signOut();
  }
}

/// A second moderator identity for moderation concurrency tests.
class SecondModerator {
  const SecondModerator({
    required this.uid,
    required this.auth,
    required this.functions,
    required this.db,
    required this.app,
  });

  final String uid;
  final FirebaseAuth auth;
  final FirebaseFunctions functions;
  final FirebaseFirestore db;
  final FirebaseApp app;

  Future<Map<String, dynamic>?> resolveReport({
    required String reportId,
    required String action,
  }) async {
    final result = await functions
        .httpsCallable('resolveReport')
        .call<Map<String, dynamic>>({
      'reportId': reportId,
      'action': action,
    });

    return result.data;
  }

  /// The report as the MODERATOR sees it.
  ///
  /// Read through this identity because `reports` requires the moderator claim,
  /// and because the assertion is about what the moderator's own write landed —
  /// checking it as anyone else would be checking a different question.
  Future<Map<String, dynamic>?> report(String reportId) async {
    return (await db.collection('reports').doc(reportId).get()).data();
  }

  Future<int> moderationLogCount(
    String reportId,
  ) async {
    final snapshot = await db
        .collection('moderation_log')
        .where(
          'report_id',
          isEqualTo: reportId,
        )
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  /// Same reasoning as SecondBuyer.dispose — no app.delete().
  Future<void> dispose() async {
    await auth.signOut();
  }
}
