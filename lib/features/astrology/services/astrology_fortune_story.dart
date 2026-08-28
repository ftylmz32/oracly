/// Personal sun-sign story: asıl mesele, then supporting insight.
library;

import '../../../core/copy/fortune_voice.dart';
import '../../../core/reading/human_reader.dart';
import 'astrology_fortune_beats.dart';
import 'astrology_theme_matter.dart';

abstract final class AstrologyFortuneStory {
  AstrologyFortuneStory._();

  static String overall({
    required String sign,
    required String catalog,
    required String feel,
    required String watch,
    required String life,
    required String domain,
    required int seed,
  }) {
    final matter = life.isNotEmpty
        ? AstrologyThemeMatter.of(life, seed)
        : _lead(sign, catalog);
    final parts = <String>[
      AstrologyFortuneBeats.start(seed, sign, matter),
      if (life.isNotEmpty) FortuneVoice.scrub(catalog) else _rest(catalog),
    ];
    if (domain.isNotEmpty) {
      parts.add(AstrologyFortuneBeats.whyDomain(domain));
    }
    final felt = FortuneVoice.scrub(feel);
    if (felt.isNotEmpty) parts.add(AstrologyFortuneBeats.feel(felt));
    final seen = FortuneVoice.scrub(watch);
    if (seen.isNotEmpty) parts.add(AstrologyFortuneBeats.watch(seen));
    var text = _close(parts, max: 6);
    if (_needsSign(text, sign)) {
      text = _close([text, AstrologyFortuneBeats.whySun(sign)], max: 7);
    }
    return text;
  }

  static String lane({
    required String sign,
    required String catalog,
    required String life,
    required int seed,
    bool question = false,
  }) {
    final body = FortuneVoice.scrub(catalog);
    if (body.isEmpty) return '';
    final parts = <String>[
      if (life.isNotEmpty)
        AstrologyFortuneBeats.lane(seed, life, body)
      else
        body,
    ];
    if (question) parts.add(AstrologyFortuneBeats.ask(life, seed));
    var text = _close(parts, max: 4);
    if (_needsSign(text, sign)) {
      text = _close([text, AstrologyFortuneBeats.whySun(sign)], max: 5);
    }
    return text;
  }

  static String inner({
    required String observed,
    required String domain,
    int seed = 0,
  }) {
    final fact = FortuneVoice.scrub(observed);
    if (fact.isEmpty) return '';
    return _close([
      AstrologyFortuneBeats.inner(seed, fact),
      if (domain.isNotEmpty) AstrologyFortuneBeats.whyDomain(domain),
    ], max: 4);
  }

  static bool _needsSign(String text, String sign) {
    final name = sign.trim();
    if (name.isEmpty) return false;
    return !text.toLowerCase().contains(name.toLowerCase());
  }

  static String _lead(String sign, String catalog) {
    var text = FortuneVoice.scrub(catalog);
    if (text.isEmpty) return sign;
    final first = _first(text);
    var out = first;
    final s = sign.trim();
    if (s.isNotEmpty && out.toLowerCase().startsWith(s.toLowerCase())) {
      out = out.substring(s.length).trim();
      if (out.startsWith(',')) out = out.substring(1).trim();
    }
    return out.isEmpty ? first : out;
  }

  static String _rest(String catalog) {
    final text = FortuneVoice.scrub(catalog);
    final first = _first(text);
    if (text.length <= first.length) return '';
    return text.substring(first.length).trim();
  }

  static String _first(String text) {
    final t = text.trim();
    final dot = t.indexOf('.');
    if (dot > 0 && dot < t.length - 1) return t.substring(0, dot + 1);
    return t.endsWith('.') ? t : '$t.';
  }

  static String _close(List<String> parts, {required int max}) {
    return HumanReader.guard(
      FortuneVoice.joinSentences(
        parts.map(FortuneVoice.scrub).where((p) => p.isNotEmpty).toList(),
        max: max,
      ),
    );
  }
}
