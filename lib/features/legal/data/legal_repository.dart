import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wave/core/error/failures.dart';
import 'package:wave/core/utils/result.dart';
import 'package:wave/features/legal/domain/legal_document.dart';

/// Legal documents, loaded from Firestore rather than bundled in the app.
///
/// Bundling them would mean an app release for a policy fix, and policy fixes
/// are sometimes urgent — a clause that turns out to be wrong, or a regulator
/// asking for a change by a date. A Firestore document can be corrected the
/// same afternoon and reaches every installed build.
class LegalRepository {
  LegalRepository(this._db, this._auth);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  static const _collection = 'legal_documents';

  Future<Result<LegalDocument>> load(LegalDocType type) async {
    try {
      final doc = await _db.collection(_collection).doc(type.slug).get();
      final data = doc.data();

      if (data == null) {
        return Err(
          NotFoundFailure(
            '${type.name} has not been published yet',
            FailureReason.documentNotPublished,
          ),
        );
      }

      return Success(
        LegalDocument(
          type: type,
          version: data['version'] as String? ?? '1.0',
          body: data['body'] as String? ?? '',
          updatedAt:
              (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
          changeSummary: data['change_summary'] as String?,
        ),
      );
    } on FirebaseException catch (e) {
      return Err(
        ServerFailure(
          e.message ?? 'Could not load the document',
          code: e.code,
          reason: FailureReason.documentLoadFailed,
        ),
      );
    }
  }

  /// Compares what this user accepted against what is currently published.
  Future<Result<AcceptanceState>> acceptanceState() async {
    final uid = _auth.currentUser?.uid;

    try {
      // Versions live in one small config document rather than requiring a
      // read of every full policy body on every cold start — the bodies are
      // long, and this runs before the first frame.
      final versionsDoc =
          await _db.collection('config').doc('legal_versions').get();
      final versions = versionsDoc.data() ?? const <String, dynamic>{};

      final current = <LegalDocType, String>{
        for (final type in LegalDocType.values)
          if (versions[type.slug] != null)
            type: versions[type.slug] as String,
      };

      if (uid == null) {
        return Success(
          AcceptanceState(acceptedVersions: const {}, currentVersions: current),
        );
      }

      final profile = await _db.collection('users').doc(uid).get();
      final accepted = profile.data()?['accepted_legal'] as Map<String, dynamic>?
          ?? const {};

      return Success(
        AcceptanceState(
          acceptedVersions: {
            for (final type in LegalDocType.values)
              if (accepted[type.slug] != null)
                type: accepted[type.slug] as String,
          },
          currentVersions: current,
        ),
      );
    } on FirebaseException catch (e) {
      // A failed fetch must not lock anyone out. Empty current versions means
      // nothing is outstanding, so the app opens normally.
      return Err(ServerFailure(e.message ?? 'Error', code: e.code));
    }
  }

  Future<Result<void>> accept(Map<LegalDocType, String> versions) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const Err(
        AuthFailure('Not signed in', reason: FailureReason.notSignedIn),
      );
    }

    try {
      await _db.collection('users').doc(uid).set({
        'accepted_legal': {
          for (final entry in versions.entries) entry.key.slug: entry.value,
        },
        'accepted_legal_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true),);

      return const Success(null);
    } on FirebaseException catch (e) {
      return Err(
        ServerFailure(
          e.message ?? 'Could not record acceptance',
          code: e.code,
          reason: FailureReason.acceptanceFailed,
        ),
      );
    }
  }
}
