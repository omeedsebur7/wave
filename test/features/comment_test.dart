import 'package:flutter_test/flutter_test.dart';
import 'package:wave/features/comments/domain/entities/comment.dart';

Comment _comment({
  bool isFromSeller = false,
  bool isPending = false,
  int likeCount = 0,
  bool likedByMe = false,
}) =>
    Comment(
      id: 'c1',
      reelId: 'r1',
      authorId: 'u1',
      authorName: 'Someone',
      text: 'Does this run true to size?',
      createdAt: DateTime(2026, 8, 4),
      isFromSeller: isFromSeller,
      isPending: isPending,
      likeCount: likeCount,
      likedByMe: likedByMe,
    );

void main() {
  group('Comment entity', () {
    test('copyWith preserves identity fields and changes only the counters', () {
      final original = _comment(isFromSeller: true, likeCount: 3);
      final liked = original.copyWith(likeCount: 4, likedByMe: true);

      expect(liked.id, original.id);
      expect(liked.text, original.text);
      // The seller badge must survive an optimistic like update — losing it
      // would make an answer from the seller look like a stranger's guess.
      expect(liked.isFromSeller, isTrue);
      expect(liked.likeCount, 4);
      expect(liked.likedByMe, isTrue);
    });

    test('a pending comment is distinguishable from a posted one', () {
      expect(_comment(isPending: true).isPending, isTrue);
      expect(_comment().isPending, isFalse);
    });

    test('equality tracks the mutable fields, so the list rebuilds on a like', () {
      expect(_comment(likeCount: 1), isNot(equals(_comment(likeCount: 2))));
      expect(_comment(likeCount: 1), equals(_comment(likeCount: 1)));
    });
  });
}
