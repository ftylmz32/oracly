/// Dream operation language — the reading follows the narrative's language.
///
/// Grounding (client guard and backend gate) is lexical: it needs the reply
/// to share words with what the dreamer wrote. So when the narrative's own
/// language can be identified deterministically, the reading is written in
/// it; otherwise the app language is used. No translation, no provider call.
///
/// Rule: Cyrillic letters are at least half of all letters → `ru`. Otherwise
/// score Latin text: TR = Turkish function words + words with a
/// Turkish-only letter; EN = English function words. A language wins only
/// when its score is more than twice the other's — a tie or a close call is
/// "unknown" and falls back to the app language.
library;

import '../../../core/l10n/app_locale.dart';

abstract final class DreamNarrativeLanguage {
  DreamNarrativeLanguage._();

  static const _tr = {
    'bir', 've', 'bu', 'şu', 'için', 'gibi', 'ile', 'ama', 'da', 'de', 'daha',
    'çok', 'sonra', 'ben', 'beni', 'bana', 'benim', 'sen', 'ne', 'mi',
    'değil', 'vardı', 'yoktu', 'rüyamda', 'gördüm', 'içinde', 'kadar',
  };

  static const _en = {
    'the', 'and', 'of', 'to', 'is', 'in', 'a', 'i', 'my', 'me', 'you',
    'your', 'that', 'this', 'with', 'it', 'as', 'for', 'was', 'were', 'what',
    'there', 'had', 'saw', 'dreamed', 'dreamt', 'not', 'but', 'into', 'from',
  };

  static final _cyrillic = RegExp('[\u0400-\u04FF]');
  static final _latin = RegExp('[A-Za-z\u00C0-\u024F]');
  static final _turkishOnly = RegExp('[çğışöüİ]');
  static final _split = RegExp('[^a-zçğıöşüâîû]+');

  /// `tr` / `en` / `ru` when identified, else null.
  static String? detect(String narrative) {
    final cyr = _cyrillic.allMatches(narrative).length;
    final lat = _latin.allMatches(narrative).length;
    if (cyr + lat == 0) return null;
    if (cyr * 2 >= cyr + lat) return AppLocale.ru;
    final words = narrative
        .replaceAll('İ', 'i')
        .toLowerCase()
        .split(_split)
        .where((w) => w.isNotEmpty);
    var tr = 0;
    var en = 0;
    for (final word in words) {
      if (_tr.contains(word) || _turkishOnly.hasMatch(word)) tr++;
      if (_en.contains(word)) en++;
    }
    if (tr > en * 2) return AppLocale.tr;
    if (en > tr * 2) return AppLocale.en;
    return null;
  }

  /// The single language captured for one Dream operation.
  static String forOperation(String narrative, String appLanguage) =>
      detect(narrative) ?? AppLocale.normalize(appLanguage);
}
