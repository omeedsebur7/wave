import 'package:equatable/equatable.dart';

class Comment extends Equatable {
  const Comment({
    required this.id,
    required this.reelId,
    required this.authorId,
    required this.authorName,
    required this.text,
    required this.createdAt,
    this.authorAvatarUrl,
    this.likeCount = 0,
    this.likedByMe = false,
    this.isFromSeller = false,
    this.isPending = false,
  });

  final String id;
  final String reelId;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String text;
  final DateTime createdAt;
  final int likeCount;
  final bool likedByMe;

  /// The Reel's publisher, badged in the thread.
  ///
  /// This matters more here than on a normal social app: a pre-purchase
  /// question ("does this run true to size?") is only worth reading if you can
  /// tell the answer came from the person selling it rather than a stranger
  /// guessing.
  final bool isFromSeller;

  /// Local echo of a comment still queued for the server.
  final bool isPending;

  Comment copyWith({int? likeCount, bool? likedByMe, bool? isPending}) =>
      Comment(
        id: id,
        reelId: reelId,
        authorId: authorId,
        authorName: authorName,
        authorAvatarUrl: authorAvatarUrl,
        text: text,
        createdAt: createdAt,
        likeCount: likeCount ?? this.likeCount,
        likedByMe: likedByMe ?? this.likedByMe,
        isFromSeller: isFromSeller,
        isPending: isPending ?? this.isPending,
      );

  @override
  List<Object?> get props => [id, likeCount, likedByMe, isPending];
}
