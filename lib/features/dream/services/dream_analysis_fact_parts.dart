/// Language-aware pieces of told dream facts — the local scaffolding only.
///
/// Observed values stay exactly as the dreamer wrote them; only connectives
/// and templates follow the operation language, so an EN/RU local section
/// never carries Turkish glue ("içinde", "ve", "bu sahne").
library;

import '../../../core/l10n/l10n.dart';
import '../models/dream_emotion.dart';
import '../models/dream_symbol.dart';
import 'dream_grounding_words.dart';

abstract final class DreamAnalysisFactParts {
  DreamAnalysisFactParts._();

  static final _prefix = {
    AppLocale.tr: RegExp(r'^rüyamda,?\s+', caseSensitive: false),
    AppLocale.en: RegExp(
      r'^(last night,?\s+)?(in my dream,?|i dreamt( that)?|i dreamed( that)?|i had a dream( that)?)\s+',
      caseSensitive: false,
    ),
    AppLocale.ru: RegExp(r'^(мне снилось,?( что)?|во сне,?)\s+',
        caseSensitive: false),
  };

  static final _pause = {
    AppLocale.tr: RegExp(r',| ve | ile | ama | fakat | ancak | derken '),
    AppLocale.en: RegExp(r',| and | but | while | when | then '),
    AppLocale.ru: RegExp(r',| и | но | а | когда | потом '),
  };

  /// Whether [value] occurs in [lower] as the dreamer's own word. Turkish
  /// inflects by suffixing, so a word start is enough there; EN/RU need the
  /// word itself (EN allows a plural), so "every" never yields "ev".
  static bool observed(String lower, String value, String language) {
    if (language == AppLocale.tr) return hasWord(lower, value.toLowerCase());
    return DreamGroundingWords.mentions(
      lower,
      value,
      english: language == AppLocale.en,
    );
  }

  /// The image as told. TR keeps the catalogue label; EN/RU show the word
  /// the dreamer used, never a Turkish label they did not write.
  static String? image(String lower, DreamSymbol symbol, String language) {
    if (observed(lower, symbol.label, language)) return symbol.label;
    if (!observed(lower, symbol.token, language)) return null;
    return language == AppLocale.tr ? symbol.label : symbol.token;
  }

  /// A chosen feeling chip in the operation language; a feeling word found
  /// in the narrative is kept only where the dreamer actually wrote it.
  static String? feeling(String emotion, String lower, String language) {
    if (language == AppLocale.tr) return emotion;
    for (final id in DreamEmotionId.values) {
      if (id.labelTr == emotion) {
        return OraclyL10n.t(
          'dream.read.feeling_word.${id.name}',
          languageCode: language,
        );
      }
    }
    return observed(lower, emotion, language) ? emotion : null;
  }

  static String scene(String told, String language) {
    var text = told.trim().replaceFirst(_prefix[language]!, '');
    if (text.isEmpty) return '';
    final period = text.indexOf(RegExp(r'[.!?]'));
    if (period > 8 && period < 110) {
      return _trimEdge(text.substring(0, period));
    }
    // No early sentence end (a run-on). Only take a fragment at a pause the
    // narrative itself contains — never hard-cut at an arbitrary word.
    final pause = text.indexOf(_pause[language]!);
    if (pause > 8 && pause < 88) return _trimEdge(text.substring(0, pause));
    return '';
  }

  static String? detail({
    required String language,
    String? image,
    String? place,
    String? person,
    required String scene,
  }) {
    String fill(String key, Map<String, String> vars) {
      var out = OraclyL10n.t('dream.read.join.$key', languageCode: language);
      vars.forEach((k, v) => out = out.replaceAll('{$k}', v));
      return out;
    }

    if (image != null &&
        place != null &&
        image.toLowerCase() != place.toLowerCase()) {
      return fill('image_place', {'image': image, 'place': place});
    }
    if (image != null && person != null) {
      return fill('image_person', {'image': image, 'person': person});
    }
    if (person != null && place != null) {
      return fill('person_place', {'person': person, 'place': place});
    }
    return image ?? person ?? place ?? (scene.isNotEmpty ? scene : null);
  }

  /// True if [token] starts a word in [text] — "tren" in "trenin", but not
  /// "at" in "saat": a genuine match never has a letter right before it.
  static bool hasWord(String text, String token) {
    if (token.isEmpty) return false;
    var index = text.indexOf(token);
    while (index != -1) {
      final before = index == 0 ? null : text[index - 1];
      if (before == null || !_isTurkishLetter(before)) return true;
      index = text.indexOf(token, index + 1);
    }
    return false;
  }

  static bool _isTurkishLetter(String char) =>
      RegExp(r'[a-zçğıöşü]', unicode: true).hasMatch(char);

  static String _trimEdge(String text) {
    var out = text.trim();
    while (out.endsWith(',') || out.endsWith('—') || out.endsWith('-')) {
      out = out.substring(0, out.length - 1).trim();
    }
    return out;
  }

  /// Places and relationships come from Turkish-only lexicons, so they are
  /// told facts only for a Turkish operation.
  static bool usesTurkishLexicon(String language) => language == AppLocale.tr;
}
