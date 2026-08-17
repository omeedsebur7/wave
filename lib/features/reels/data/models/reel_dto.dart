import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wave/features/reels/domain/entities/reel.dart';

/// Firestore <-> domain mapping.
///
/// Written by hand rather than generated because the counter fields are
/// materialised (`likes_count`) rather than stored where you'd expect, and the
/// mapping is worth being explicit about.
class ReelDto {
  const ReelDto({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.bunnyVideoId,
    required this.thumbnailUrl,
    required this.caption,
    required this.createdAt,
    required this.durationSeconds,
    this.authorAvatarUrl,
    this.linkedProductId,
    this.linkedProductPriceMinor,
    this.linkedProductCurrency,
    this.likeCount = 0,
    this.viewCount = 0,
    this.commentCount = 0,
    this.rankScore = 0,
  });

  factory ReelDto.fromFirestore(String id, Map<String, dynamic> json) {
    return ReelDto(
      id: id,
      authorId: json['author_id'] as String? ?? '',
      authorName: json['author_name'] as String? ?? '',
      authorAvatarUrl: json['author_avatar_url'] as String?,
      bunnyVideoId: json['bunny_video_id'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String? ?? '',
      caption: json['caption'] as String? ?? '',
      createdAt:
          (json['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      linkedProductId: json['linked_product_id'] as String?,
      linkedProductPriceMinor:
          (json['linked_product_price_minor'] as num?)?.toInt(),
      linkedProductCurrency: json['linked_product_currency'] as String?,
      likeCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      viewCount: (json['views_count'] as num?)?.toInt() ?? 0,
      commentCount: (json['comments_count'] as num?)?.toInt() ?? 0,
      rankScore: (json['rank_score'] as num?)?.toDouble() ?? 0,
    );
  }

  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String bunnyVideoId;
  final String thumbnailUrl;
  final String caption;
  final DateTime createdAt;
  final int durationSeconds;
  final String? linkedProductId;
  final int? linkedProductPriceMinor;
  final String? linkedProductCurrency;
  final int likeCount;
  final int viewCount;
  final int commentCount;
  final double rankScore;

  Reel toDomain({bool likedByMe = false, bool savedByMe = false}) => Reel(
        id: id,
        authorId: authorId,
        authorName: authorName,
        authorAvatarUrl: authorAvatarUrl,
        bunnyVideoId: bunnyVideoId,
        thumbnailUrl: thumbnailUrl,
        caption: caption,
        createdAt: createdAt,
        durationSeconds: durationSeconds,
        linkedProductId: linkedProductId,
        likeCount: likeCount,
        viewCount: viewCount,
        commentCount: commentCount,
        likedByMe: likedByMe,
        savedByMe: savedByMe,
        rankScore: rankScore,
      );
}
