/// Body–sign near-claim grounding (connector-aware).
library;

import '../request/yildizname_narrative_request.dart';
import '../result/yildizname_result_error.dart';
import 'yildizname_grounding_lexicon.dart';

abstract final class YildiznameQualityBodyGrounding {
  YildiznameQualityBodyGrounding._();

  static const _angles = {'ascendant', 'midheaven'};

  static void validate(
    YildiznameNarrativeRequest request,
    String prose,
  ) {
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
        final be = RegExp.escape(b);
        final se = RegExp.escape(s);
        final patterns = [
          RegExp('$be\\s+(?:in|в)\\s+$se', caseSensitive: false),
          RegExp('$be\\s+$se(?:\'d[ae]|\'t[ae])?', caseSensitive: false),
          RegExp('$be.{0,6}$se\\s*burcunda', caseSensitive: false),
          RegExp('$se\\s+$be', caseSensitive: false),
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
      final se = RegExp.escape(s);
      final RegExp rising;
      if (bodyKey == 'ascendant') {
        rising = RegExp(
          '$se\\s+(?:rising|yükselen|yukselen)|'
          '(?:ascendant|асцендент|yükselen|yukselen).{0,12}$se',
          caseSensitive: false,
        );
      } else {
        rising = RegExp(
          '(?:midheaven|\\bmc\\b|gökyüzü).{0,12}$se|'
          '$se\\s+(?:midheaven|\\bmc\\b)',
          caseSensitive: false,
        );
      }
      if (rising.hasMatch(prose)) return true;
    }
    return _planetClaim(prose, bodyTokens, signTokens);
  }
}
