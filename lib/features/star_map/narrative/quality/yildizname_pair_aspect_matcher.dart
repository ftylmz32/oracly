/// Aspect-pair claims (`Ay—Mars kare`, `Sun-Moon trine`, `Солнце — Луна
/// квадрат`) read from prose with the shared lexical rules.
///
/// Both bodies and the aspect word come from [YildiznameGroundingLexicon]
/// through [YildiznameLexicalToken], so a claim can never start inside an
/// unrelated word (`ay` in `detay—Mars kare`, `sun` in `Sunset—Moon`, `trine`
/// in `doctrine`). Canonical names are read from which named alternative
/// matched — never re-derived by substring search on the matched text.
library;

import 'yildizname_grounding_lexicon.dart';
import 'yildizname_lexical_token.dart';

typedef YildiznameAspectClaim = ({String bodyA, String bodyB, String type});

abstract final class YildiznamePairAspectMatcher {
  YildiznamePairAspectMatcher._();

  /// Angles are not aspect partners in the Narrative contract.
  static const _angles = {'ascendant', 'midheaven'};

  static final _bodies = [
    for (final key in YildiznameGroundingLexicon.bodies.keys)
      if (!_angles.contains(key)) key,
  ];

  static final _types = YildiznameGroundingLexicon.aspectWords.keys.toList();

  /// Compiled once for the process — never per validation.
  static final _pattern = YildiznameLexicalToken.compile(
    '${_bodyGroup('a')}\\s*[–\\-—]\\s*${_bodyGroup('b')}'
    '.{0,20}'
    '(?:${_types.map((t) {
      final words = YildiznameGroundingLexicon.aspectWords[t]!;
      return '(?<t_$t>${YildiznameLexicalToken.anyAspect(words)})';
    }).join('|')})',
  );

  static String _bodyGroup(String side) => '(?:${_bodies.map((b) {
        final tokens = YildiznameGroundingLexicon.bodies[b]!;
        return '(?<${side}_$b>${YildiznameLexicalToken.anyBody(tokens)})';
      }).join('|')})';

  /// Every aspect-pair claim in [prose], in canonical lexicon keys.
  static Iterable<YildiznameAspectClaim> claims(String prose) sync* {
    final text = YildiznameLexicalToken.normalizeProse(prose);
    for (final m in _pattern.allMatches(text)) {
      yield (
        bodyA: _matched(m, 'a', _bodies),
        bodyB: _matched(m, 'b', _bodies),
        type: _matched(m, 't', _types),
      );
    }
  }

  static String _matched(RegExpMatch m, String side, List<String> keys) =>
      keys.firstWhere((k) => m.namedGroup('${side}_$k') != null);
}
