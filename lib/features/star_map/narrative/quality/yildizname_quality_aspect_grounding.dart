/// House and aspect claim grounding.
library;

import '../request/yildizname_narrative_request.dart';
import '../result/yildizname_result_error.dart';
import 'yildizname_grounding_lexicon.dart';

abstract final class YildiznameQualityAspectGrounding {
  YildiznameQualityAspectGrounding._();

  static final _pairAspect = RegExp(
    r'(sun|moon|mercury|venus|mars|jupiter|saturn|uranus|neptune|pluto|'
    r'güneş|gunes|ay|merkür|merkur|venüs|jüpiter|satürn|uranüs|neptün|plüton|'
    r'солнц\w*|лун\w*|меркур\w*|венер\w*|марс\w*|юпитер\w*|сатурн\w*)'
    r'\s*[–\-—]\s*'
    r'(sun|moon|mercury|venus|mars|jupiter|saturn|uranus|neptune|pluto|'
    r'güneş|gunes|ay|merkür|merkur|venüs|jüpiter|satürn|uranüs|neptün|plüton|'
    r'солнц\w*|лун\w*|меркур\w*|венер\w*|марс\w*|юпитер\w*|сатурн\w*)'
    r'.{0,20}'
    r'(conjunction|sextile|square|trine|opposition|'
    r'kavuşum|kavusum|sekstil|kare|üçgen|ucgen|karşıt|karsit|'
    r'соединен\w*|секстиль|квадрат|трин\w*|оппозиц\w*)',
    caseSensitive: false,
  );

  static void validateHouses(
    YildiznameNarrativeRequest request,
    String prose,
  ) {
    final houseByBody = <String, int>{
      for (final p in request.placements)
        if (p.house != null) p.body: p.house!,
    };
    final re = RegExp(
      r'(\d+)\s*(?:\.?\s*)?(?:ev|house|доме)',
      caseSensitive: false,
    );
    for (final m in re.allMatches(prose)) {
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
    for (final m in _pairAspect.allMatches(prose)) {
      final a = _canonBody(m.group(1)!);
      final b = _canonBody(m.group(2)!);
      final type = _canonType(m.group(3)!);
      if (a == null || b == null || type == null) continue;
      final key = '$a|$b|$type';
      if (!known.contains(key)) {
        throw YildiznameResultException(
          YildiznameResultErrorKind.grounding,
          'aspect:$key',
        );
      }
    }
  }

  static String? _canonBody(String raw) {
    final t = raw.toLowerCase();
    for (final e in YildiznameGroundingLexicon.bodies.entries) {
      if (e.key == 'ascendant' || e.key == 'midheaven') continue;
      for (final tok in e.value) {
        final tip = tok.trim();
        if (tip.isNotEmpty && t.contains(tip)) return e.key;
      }
    }
    return null;
  }

  static String? _canonType(String raw) {
    final t = raw.toLowerCase();
    for (final e in YildiznameGroundingLexicon.aspectWords.entries) {
      if (e.value.any((w) => t.contains(w))) return e.key;
    }
    return null;
  }
}
