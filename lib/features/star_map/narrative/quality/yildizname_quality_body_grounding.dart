/// Body–sign near-claim grounding (connector-aware).
library;

import '../request/yildizname_narrative_request.dart';
import '../result/yildizname_result_error.dart';
import 'yildizname_grounding_lexicon.dart';
import 'yildizname_lexical_token.dart';

abstract final class YildiznameQualityBodyGrounding {
  YildiznameQualityBodyGrounding._();

  /// ONE consolidated pattern per (body, sign), compiled once and reused for
  /// every validation. (Compiling thousands of per-token patterns on each
  /// call froze the UI for ~50 s on a phone — see Phase 8C.2b.)
  static final _claims = <String, RegExp>{};

  static void validate(YildiznameNarrativeRequest request, String rawProse) {
    final prose = YildiznameLexicalToken.normalizeProse(rawProse);
    final byBody = <String, String>{
      for (final p in request.placements) p.body: p.sign,
    };
    for (final a in request.angles) {
      byBody[a.kind] = a.sign;
    }
    for (final body in YildiznameGroundingLexicon.bodies.keys) {
      for (final signKey in YildiznameGroundingLexicon.signs.keys) {
        if (!_claim(body, signKey).hasMatch(prose)) continue;
        final expected = byBody[body];
        if (expected == null) {
          throw YildiznameResultException(
            YildiznameResultErrorKind.grounding,
            '$body unavailable ($signKey)',
          );
        }
        if (expected != signKey) {
          throw YildiznameResultException(
            YildiznameResultErrorKind.grounding,
            '$body expected $expected got $signKey',
          );
        }
      }
    }
  }

  static RegExp _claim(String body, String signKey) =>
      _claims.putIfAbsent('$body|$signKey', () => _build(body, signKey));

  static RegExp _build(String body, String signKey) {
    // Body: a genuine word occurrence (never a mere prefix of a longer,
    // unrelated word). Sign: a WHOLE word.
    final be = YildiznameLexicalToken.anyBody(
      YildiznameGroundingLexicon.bodies[body]!,
    );
    final se = YildiznameLexicalToken.anySign(
      YildiznameGroundingLexicon.signs[signKey]!,
    );
    final forms = <String>[
      '$be\\s+(?:in|в)\\s+$se',
      '$be\\s+$se',
      '$be.{0,6}$se\\s*burcunda',
      '$se\\s+$be',
    ];
    if (body == 'ascendant') {
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
      forms
        ..add('$se\\s+$after')
        ..add('$before.{0,12}$se');
    } else if (body == 'midheaven') {
      final mc = YildiznameLexicalToken.whole('mc');
      final mid = YildiznameLexicalToken.start('midheaven');
      // The whole name `gökyüzü ortası` (inflected: `ortasında`), never bare
      // `gökyüzü` — `Gökyüzünde Aslan …` ("in the sky") is not a Midheaven.
      final sky = '${YildiznameLexicalToken.start('gökyüzü')}\\s+ortas';
      forms
        ..add('(?:$mid|$mc|$sky).{0,12}$se')
        ..add('$se\\s+(?:$mid|$mc)');
    }
    return YildiznameLexicalToken.compile(forms.map((f) => '(?:$f)').join('|'));
  }
}
