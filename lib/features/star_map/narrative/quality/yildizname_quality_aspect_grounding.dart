/// House and aspect claim grounding.
library;

import '../request/yildizname_narrative_request.dart';
import '../result/yildizname_result_error.dart';
import 'yildizname_grounding_lexicon.dart';
import 'yildizname_lexical_token.dart';
import 'yildizname_pair_aspect_matcher.dart';

abstract final class YildiznameQualityAspectGrounding {
  YildiznameQualityAspectGrounding._();

  /// `<n>. ev` / `<n> house` / `<n> доме` — the house word is a real word
  /// (`evde`, `evindeki`), never `evre` / `evren` / `evet`. Compiled once.
  static final _houseClaim = YildiznameLexicalToken.compile(
    '(\\d+)\\s*\\.?\\s*${YildiznameLexicalToken.house()}',
  );

  static void validateHouses(YildiznameNarrativeRequest request, String raw) {
    final prose = YildiznameLexicalToken.normalizeProse(raw);
    final houseByBody = <String, int>{
      for (final p in request.placements)
        if (p.house != null) p.body: p.house!,
    };
    for (final m in _houseClaim.allMatches(prose)) {
      final n = int.tryParse(m.group(1) ?? '');
      if (n == null) continue;
      final start = (m.start - 40).clamp(0, prose.length);
      final chunk = prose.substring(start, m.end);
      for (final entry in YildiznameGroundingLexicon.bodies.entries) {
        if (entry.key == 'ascendant' || entry.key == 'midheaven') continue;
        if (!YildiznameGroundingLexicon.hasBody(chunk, entry.key)) continue;
        final expected = houseByBody[entry.key];
        if (expected == null || expected != n) {
          throw YildiznameResultException(
            YildiznameResultErrorKind.grounding,
            'house:${entry.key}:$n',
          );
        }
      }
    }
  }

  static void validateAspects(
    YildiznameNarrativeRequest request,
    String prose,
  ) {
    final known = <String>{
      for (final a in request.aspects) ...{
        '${a.bodyA}|${a.bodyB}|${a.type}',
        '${a.bodyB}|${a.bodyA}|${a.type}',
      },
    };
    for (final claim in YildiznamePairAspectMatcher.claims(prose)) {
      final key = '${claim.bodyA}|${claim.bodyB}|${claim.type}';
      if (!known.contains(key)) {
        throw YildiznameResultException(
          YildiznameResultErrorKind.grounding,
          'aspect:$key',
        );
      }
    }
  }
}
