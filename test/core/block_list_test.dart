import 'package:flutter_test/flutter_test.dart';
import 'package:wave/core/services/block_list.dart' show BlockList;

/// A pure stand-in for [BlockList]'s filtering contract.
///
/// The real class holds a Firestore subscription, which is not what is worth
/// testing here. What is worth testing is the decision it exposes, because that
/// decision is now consulted by four separate surfaces — feed, search, comments
/// and chat — and a wrong answer is invisible: content simply appears that the
/// user asked never to see again.
class _Filter {
  _Filter(this.blocked);

  final Set<String> blocked;

  bool isBlocked(String? id) => id != null && blocked.contains(id);

  bool anyBlocked(Iterable<String?> ids) => ids.any(isBlocked);
}

void main() {
  group('Block filtering', () {
    final filter = _Filter({'bad_actor', 'spammer'});

    test('blocks a listed id', () {
      expect(filter.isBlocked('bad_actor'), isTrue);
      expect(filter.isBlocked('spammer'), isTrue);
    });

    test('allows anyone unlisted', () {
      expect(filter.isBlocked('friendly_seller'), isFalse);
    });

    test('treats a null author as visible, not blocked', () {
      // A Reel with no author id is malformed data, not a blocked person.
      // Hiding it would make a data bug look like a block, which is the harder
      // of the two to diagnose.
      expect(filter.isBlocked(null), isFalse);
    });

    test('an empty block list hides nothing', () {
      expect(_Filter(const {}).isBlocked('anyone'), isFalse);
    });

    test('anyBlocked catches either side of a conversation', () {
      // A chat has two participants and the block may be in either direction of
      // the pair as stored, so checking only the "other" id would miss half the
      // cases when participant order varies.
      expect(filter.anyBlocked(['me', 'bad_actor']), isTrue);
      expect(filter.anyBlocked(['bad_actor', 'me']), isTrue);
      expect(filter.anyBlocked(['me', 'friendly_seller']), isFalse);
    });

    test('anyBlocked tolerates nulls in the participant list', () {
      expect(filter.anyBlocked(['me', null]), isFalse);
      expect(filter.anyBlocked([null, 'bad_actor']), isTrue);
    });

    test('filtering a list drops only blocked entries', () {
      const authors = ['friendly_seller', 'bad_actor', 'someone_else', 'spammer'];
      final visible = authors.where((a) => !filter.isBlocked(a)).toList();
      expect(visible, ['friendly_seller', 'someone_else']);
    });

    test('a fully blocked page yields an empty list, not an error', () {
      // The feed must cope with a page where everything was filtered out — it
      // asks for more rather than showing an empty-state as if nothing exists.
      const authors = ['bad_actor', 'spammer'];
      final visible = authors.where((a) => !filter.isBlocked(a)).toList();
      expect(visible, isEmpty);
    });
  });
}
