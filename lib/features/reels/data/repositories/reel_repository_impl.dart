import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:wave/core/error/failures.dart';
import 'package:wave/core/utils/result.dart';
import 'package:wave/features/reels/data/datasources/reel_remote_data_source.dart';
import 'package:wave/features/reels/domain/entities/reel.dart';
import 'package:wave/features/reels/domain/repositories/reel_repository.dart';


class ReelRepositoryImpl implements ReelRepository {
  ReelRepositoryImpl(this._remote, this._auth);

  final ReelRemoteDataSource _remote;
  final FirebaseAuth _auth;

  String? get _uid => _auth.currentUser?.uid;

  @override
  Future<Result<ReelPage>> fetchFeed({Object? cursor, int limit = 8}) async {
    try {
      final (dtos, nextCursor, hasMore) = await _remote.fetchPage(
        cursor: cursor as DocumentSnapshot<Map<String, dynamic>>?,
        limit: limit,
      );

      // One batched membership lookup rather than a per-Reel read inside the
      // list builder.
      final uid = _uid;
      final liked = uid == null
          ? <String>{}
          : await _remote.likedReelIds(uid, dtos.map((d) => d.id).toList());

      return Success(
        ReelPage(
          reels: [
            for (final d in dtos) d.toDomain(likedByMe: liked.contains(d.id)),
          ],
          cursor: nextCursor,
          hasMore: hasMore,
        ),
      );
    } on FirebaseException catch (e) {
      return Err(
        ServerFailure(
          e.message ?? 'Could not load Reels',
          code: e.code,
          reason: FailureReason.reelsLoadFailed,
        ),
      );
    } catch (_) {
      // Anything not a FirebaseException at this point is a transport failure;
      // the user needs 'no connection', not a stack trace.
      return const Err(NetworkFailure());
    }
  }

  @override
  Future<Result<Reel>> fetchById(String reelId) async {
    try {
      final dto = await _remote.fetchById(reelId);
      if (dto == null) {
        return const Err(
          NotFoundFailure('Reel not found', FailureReason.reelNotFound),
        );
      }
      return Success(dto.toDomain());
    } on FirebaseException catch (e) {
      return Err(ServerFailure(e.message ?? 'Error', code: e.code));
    }
  }

  @override
  Future<Result<List<Reel>>> search(String query, {int limit = 20}) async {
    final term = query.trim().toLowerCase();
    if (term.isEmpty) return const Success([]);

    try {
      // \uf8ff is the highest code point, so [term, term+\uf8ff] is every
      // string starting with term. caption_lower is written at publish time.
      final snap = await _remote.searchByCaption(term, limit: limit);
      return Success([for (final d in snap) d.toDomain()]);
    } on FirebaseException catch (e) {
      return Err(
        ServerFailure(
          e.message ?? 'Search failed',
          code: e.code,
          reason: FailureReason.searchFailed,
        ),
      );
    }
  }

  @override
  Future<Result<List<Reel>>> byAuthor(String authorId, {int limit = 30}) async {
    try {
      final dtos = await _remote.byAuthor(authorId, limit: limit);
      return Success([for (final d in dtos) d.toDomain()]);
    } on FirebaseException catch (e) {
      return Err(ServerFailure(e.message ?? 'Error', code: e.code));
    }
  }

  @override
  Future<Result<void>> like(String reelId) => _setLike(reelId, true);

  @override
  Future<Result<void>> unlike(String reelId) => _setLike(reelId, false);

  Future<Result<void>> _setLike(String reelId, bool liked) async {
    final uid = _uid;
    if (uid == null) {
      return const Err(
        AuthFailure(
          'Sign in to like Reels',
          reason: FailureReason.signInToLikeReels,
        ),
      );
    }
    try {
      await _remote.setLike(reelId: reelId, userId: uid, liked: liked);
      return const Success(null);
    } on FirebaseException catch (e) {
      return Err(ServerFailure(e.message ?? 'Error', code: e.code));
    }
  }

  @override
  Future<Result<int>> exactLikeCount(String reelId) async {
    try {
      return Success(await _remote.authoritativeLikeCount(reelId));
    } on FirebaseException catch (e) {
      return Err(ServerFailure(e.message ?? 'Error', code: e.code));
    }
  }

  @override
  Future<Result<void>> recordView(String reelId) async {
    final uid = _uid;
    // Guests count as views too — the counter is anonymous by design.
    try {
      await _remote.recordView(reelId: reelId, userId: uid ?? 'guest');
      return const Success(null);
    } catch (_) {
      // A dropped view count is not worth surfacing to the user.
      return const Success(null);
    }
  }

  @override
  Future<Result<void>> toggleSave(String reelId, {required bool saved}) async {
    final uid = _uid;
    if (uid == null) {
      return const Err(
        AuthFailure(
          'Sign in to save Reels',
          reason: FailureReason.signInToSaveReels,
        ),
      );
    }
    try {
      await _remote.toggleSave(reelId: reelId, userId: uid, saved: saved);
      return const Success(null);
    } on FirebaseException catch (e) {
      return Err(ServerFailure(e.message ?? 'Error', code: e.code));
    }
  }
}
