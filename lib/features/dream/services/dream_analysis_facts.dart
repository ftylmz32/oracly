/// Observed dream facts — told text only, never a life story.
library;

import '../../../core/l10n/app_locale.dart';
import '../models/dream.dart';
import '../models/dream_relationship.dart';
import 'dream_analysis_fact_parts.dart';

class DreamAnalysisFacts {
  const DreamAnalysisFacts({
    required this.told,
    required this.scene,
    this.emotion,
    this.image,
    this.companion,
    this.place,
    this.person,
    this.tag,
    this.detail,
    this.feelings = '',
    this.language = AppLocale.tr,
  });

  final String told;

  /// The stated feeling words the request carried (chips and narrative
  /// feeling words) — evidence for the emotional theme only.
  final String feelings;
  final String scene;
  final String? emotion;
  final String? image;
  final String? companion;
  final String? place;
  final String? person;
  final String? tag;
  final String? detail;

  /// Operation language captured once before the request — guard and local
  /// beats read this, never the live app locale.
  final String language;

  bool get isEmpty => told.isEmpty;

  /// These facts with [context] — the safe connected memory actually sent
  /// with the request — also counted as told. Only the daily reflection
  /// may lean on it; every other section stays bound to the Dream.
  DreamAnalysisFacts withContext(String? context) {
    final extra = context?.trim() ?? '';
    if (extra.isEmpty) return this;
    return DreamAnalysisFacts(
      told: '$told $extra',
      scene: scene,
      emotion: emotion,
      image: image,
      companion: companion,
      place: place,
      person: person,
      tag: tag,
      detail: detail,
      feelings: feelings,
      language: language,
    );
  }

  static DreamAnalysisFacts from({
    required String narrative,
    required DreamUnderstanding understanding,
    List<String> tags = const [],
    List<String> statedFeelings = const [],
    String language = AppLocale.tr,
  }) {
    final lang = AppLocale.normalize(language);
    final told = narrative.trim().replaceAll(RegExp(r'\s+'), ' ');
    final images = [
      for (final symbol in understanding.symbols)
        ?DreamAnalysisFactParts.image(told, symbol, lang),
    ];
    final lexicon = DreamAnalysisFactParts.usesTurkishLexicon(lang);
    final place =
        lexicon ? _firstWhere(understanding.locations, told) : null;
    final person =
        lexicon ? _firstPerson(understanding.relationships, told) : null;
    final emotion = understanding.emotions.isEmpty
        ? null
        : DreamAnalysisFactParts.feeling(
            understanding.emotions.first,
            told,
            lang,
          );
    final tag = tags.where((t) => t.trim().isNotEmpty).firstOrNull;
    final image = images.isEmpty ? null : images.first;
    final companion = images.length > 1 ? images[1] : null;
    final scene = DreamAnalysisFactParts.scene(told, lang);
    return DreamAnalysisFacts(
      told: told,
      scene: scene,
      emotion: emotion,
      image: image,
      companion: companion,
      place: place,
      person: person,
      tag: tag,
      detail: DreamAnalysisFactParts.detail(
        language: lang,
        image: image,
        place: place,
        person: person,
        scene: scene,
      ),
      feelings: statedFeelings.join(' '),
      language: lang,
    );
  }

  static String? _firstWhere(List<String> values, String told) {
    for (final value in values) {
      if (value.trim().isEmpty) continue;
      if (_hasWord(told, value) || _hasWord(told, value.split(' ').first)) {
        return value;
      }
    }
    return values.where((v) => v.trim().isNotEmpty).firstOrNull;
  }

  static String? _firstPerson(
    List<DreamRelationship> people,
    String told,
  ) {
    for (final person in people) {
      final label = person.label.trim();
      if (label.isEmpty) continue;
      if (_hasWord(told, label)) return label;
    }
    return people
        .map((p) => p.label.trim())
        .where((l) => l.isNotEmpty)
        .firstOrNull;
  }

  static bool _hasWord(String text, String token) =>
      DreamAnalysisFactParts.observed(text, token, AppLocale.tr);
}
