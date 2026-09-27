/// Body–sign near-claim grounding (connector-aware).
library;

import '../request/yildizname_narrative_request.dart';
import '../result/yildizname_result_error.dart';
import 'yildizname_grounding_lexicon.dart';
import 'yildizname_lexical_token.dart';

abstract final class YildiznameQualityBodyGrounding {
  YildiznameQualityBodyGrounding._();

  static const _angles = {'ascendant', 'midheaven'};

  static void validate(
    YildiznameNarrativeRequest request,
    String rawProse,
  ) {
    final prose = YildiznameLexicalToken.normalizeProse(rawProse);
    final byBody = <String, String>{
      for (final p in request.placements) p.body: p.sign,
    };
    for (final a in request.angles) {
      byBody[a.kind] = a.sign;
    }
    for (final bodyEntry in YildiznameGroundingLexicon.bodies.entries) {
      final body = bodyEntry.key;
      for (final signEntry in YildiznameGroundingLexicon.signs.entries) {
        final hit = _angles.contains(body)
            ? _angleClaim(prose, body, bodyEntry.value, signEntry.value)
            : _planetClaim(prose, bodyEntry.value, signEntry.value);
        if (!hit) continue;
        final expected = byBody[body];
        if (expected == null) {
          throw YildiznameResultException(
            YildiznameResultErrorKind.grounding,
            '$body unavailable (${signEntry.key})',
          );
        }
        if (expected != signEntry.key) {
          throw YildiznameResultException(
            YildiznameResultErrorKind.grounding,
            '$body expected $expected got ${signEntry.key}',
          );
        }
      }
    }
  }

  static bool _planetClaim(
    String prose,
    List<String> bodyTokens,
    List<String> signTokens,
  ) {
    for (final b in bodyTokens) {
      for (final s in signTokens) {
        // Body: a word START (inflection may follow). Sign: a WHOLE word.
        final be = YildiznameLexicalToken.start(b);
        final se = YildiznameLexicalToken.sign(s);
        final patterns = [
          YildiznameLexicalToken.compile('$be\\s+(?:in|в)\\s+$se'),
          YildiznameLexicalToken.compile('$be\\s+$se'),
          YildiznameLexicalToken.compile('$be.{0,6}$se\\s*burcunda'),
          YildiznameLexicalToken.compile('$se\\s+$be'),
        ];
        if (patterns.any((re) => re.hasMatch(prose))) return true;
      }
    }
    return false;
  }

  static bool _angleClaim(
    String prose,
    String bodyKey,
    List<String> bodyTokens,
    List<String> signTokens,
  ) {
    for (final s in signTokens) {
      final se = YildiznameLexicalToken.sign(s);
      final RegExp rising;
      if (bodyKey == 'ascendant') {
        final after = YildiznameLexicalToken.anyStart(const [
          'rising',
          'yükselen',
          'yukselen',
        ]);
        final before = YildiznameLexicalToken.anyStart(const [
          'ascendant',
          'асцендент',
          'yükselen',
          'yukselen',
        ]);
        rising = YildiznameLexicalToken.compile(
          '$se\\s+$after|$before.{0,12}$se',
        );
      } else {
        final mc = YildiznameLexicalToken.whole('mc');
        final mid = YildiznameLexicalToken.start('midheaven');
        final sky = YildiznameLexicalToken.start('gökyüzü');
        rising = YildiznameLexicalToken.compile(
          '(?:$mid|$mc|$sky).{0,12}$se|$se\\s+(?:$mid|$mc)',
        );
      }
      if (rising.hasMatch(prose)) return true;
    }
    return _planetClaim(prose, bodyTokens, signTokens);
  }
}
