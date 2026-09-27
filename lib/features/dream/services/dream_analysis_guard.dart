/// Reject dictionary, medical, certainty, and invented dream images.
library;

import '../../../core/copy/fortune_voice.dart';
import '../../../core/reading/human_reader.dart';
import '../../../core/reading/ai_output_quality_context.dart';
import '../../../core/reading/ai_output_quality_gate.dart';
import '../../../core/reading/ai_output_quality_kind.dart';
import '../../content/dream/data/dream_symbol_catalogue.dart';
import 'dream_analysis_facts.dart';
import 'dream_grounding_words.dart';

abstract final class DreamAnalysisGuard {
  DreamAnalysisGuard._();

  static const dictionary = [
    'anlam:',
    'rüyanda:',
    'temsil eder',
    'demektir',
    'sözlük',
    'rüya tabiri',
    'tabirname',
    ' = ',
    'meaning:',
    'symbolizes',
    'dream dictionary',
    'значение:',
    'символизирует',
    'сонник',
  ];

  static bool looksDictionary(String text) {
    final lower = text.toLowerCase();
    return dictionary.any(lower.contains);
  }

  static bool isSpeakable(String text, DreamAnalysisFacts facts) {
    final trimmed = text.trim();
    if (trimmed.length < 24) return false;
    if (looksDictionary(trimmed)) return false;
    if (FortuneVoice.claimsMedical(trimmed)) return false;
    if (FortuneVoice.claimsCertainty(trimmed)) return false;
    if (HumanReader.looksGeneric(trimmed)) return false;
    if (!AiOutputQualityGate.validate(
      trimmed,
      kind: AiOutputQualityKind.dream,
      context: AiOutputQualityContext(localeCode: facts.language),
    ).isAcceptable) {
      return false;
    }
    if (_inventsImage(trimmed, facts)) return false;
    if (facts.told.isNotEmpty && !_touchesTold(trimmed, facts)) return false;
    return true;
  }

  static String? polish(String? text, DreamAnalysisFacts facts) {
    if (text == null) return null;
    final guarded = HumanReader.guard(FortuneVoice.scrub(text));
    if (!isSpeakable(guarded, facts)) return null;
    return guarded;
  }

  static final _questionMark = RegExp('[?？]');

  static int questionMarks(String text) =>
      _questionMark.allMatches(text).length;

  /// The closing contract: exactly one open question (TR / EN / RU all use
  /// `?`). None, or two and more, is rejected — never trimmed into one.
  static String? conclusion(String? text, DreamAnalysisFacts facts) {
    if (text == null || questionMarks(text) != 1) return null;
    final polished = polish(text, facts);
    if (polished != null && questionMarks(polished) == 1) return polished;
    return oneQuestion(text, facts);
  }

  static String? oneQuestion(String? text, DreamAnalysisFacts facts) {
    if (text == null) return null;
    final guarded = HumanReader.guard(text.trim());
    if (!guarded.contains(_questionMark)) return null;
    final q = guarded.split(_questionMark).first.trim();
    if (q.isEmpty) return null;
    final ask = '$q?';
    if (looksDictionary(ask) || FortuneVoice.claimsMedical(ask)) return null;
    if (facts.told.isNotEmpty && !_touchesTold(ask, facts)) return null;
    if (ask.contains('\n')) return null;
    return ask;
  }

  static bool _touchesTold(String text, DreamAnalysisFacts facts) {
    for (final token in [
      facts.image,
      facts.companion,
      facts.place,
      facts.person,
      facts.emotion,
      facts.tag,
    ]) {
      if (token != null && DreamGroundingWords.mentions(text, token)) {
        return true;
      }
    }
    // A paraphrase of the told narrative still counts as grounded, so check
    // every significant word the user wrote — TR, EN and RU alike.
    final toldWords = DreamGroundingWords.significant(facts.told);
    if (toldWords.isEmpty) return false;
    return DreamGroundingWords.overlaps(
      DreamGroundingWords.significant(text),
      toldWords,
    );
  }

  /// Catalogue images exist in Turkish and English only. Russian prose is
  /// never matched here; it stays bound by the narrative grounding above.
  static bool _inventsImage(String text, DreamAnalysisFacts facts) {
    for (final item in DreamSymbolCatalogue.all) {
      final inText = DreamGroundingWords.mentions(text, item.tokenTr) ||
          DreamGroundingWords.mentions(text, item.token, english: true);
      if (!inText) continue;
      final told = DreamGroundingWords.mentions(facts.told, item.tokenTr) ||
          DreamGroundingWords.mentions(facts.told, item.token, english: true);
      if (told) continue;
      return true;
    }
    return false;
  }
}
