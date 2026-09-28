/// Reject dictionary, medical, certainty, and invented dream images.
library;

import '../../../core/copy/fortune_voice.dart';
import '../../../core/reading/human_reader.dart';
import '../../../core/reading/ai_output_quality_context.dart';
import '../../../core/reading/ai_output_quality_gate.dart';
import '../../../core/reading/ai_output_quality_kind.dart';
import 'dream_analysis_facts.dart';
import 'dream_grounding_words.dart';
import 'dream_guard_context.dart';
import 'dream_invented_image.dart';
import 'dream_stated_feeling.dart';

export 'dream_guard_context.dart';

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

  static bool isSpeakable(String text, DreamAnalysisFacts facts,
      {DreamGuardRole role = DreamGuardRole.dream,
      DreamGuardSource source = DreamGuardSource.local}) {
    final trimmed = text.trim();
    if (trimmed.length < 24) return false;
    if (looksDictionary(trimmed)) return false;
    if (FortuneVoice.claimsMedical(trimmed)) return false;
    if (FortuneVoice.claimsCertainty(trimmed)) return false;
    if (source == DreamGuardSource.local && HumanReader.looksGeneric(trimmed)) {
      return false;
    }
    if (!AiOutputQualityGate.validate(
      trimmed,
      kind: AiOutputQualityKind.dream,
      context: AiOutputQualityContext(localeCode: facts.language),
    ).isAcceptable) {
      return false;
    }
    if (DreamInventedImage.invents(trimmed, facts)) return false;
    if (facts.told.isNotEmpty &&
        !_touchesTold(trimmed, facts) &&
        !(role == DreamGuardRole.emotionalTheme &&
            DreamStatedFeeling.shares(
                trimmed, '${facts.told} ${facts.feelings}'))) {
      return false;
    }
    return true;
  }

  static String? polish(String? text, DreamAnalysisFacts facts,
      {DreamGuardRole role = DreamGuardRole.dream,
      DreamGuardSource source = DreamGuardSource.local}) {
    if (text == null) return null;
    final guarded = HumanReader.guard(FortuneVoice.scrub(text));
    if (!isSpeakable(guarded, facts, role: role, source: source)) return null;
    return guarded;
  }

  static final _questionMark = RegExp('[?？]');

  static int questionMarks(String text) =>
      _questionMark.allMatches(text).length;

  /// The closing contract: exactly one open question (TR / EN / RU all use
  /// `?`). None, or two and more, is rejected — never trimmed into one.
  static String? conclusion(String? text, DreamAnalysisFacts facts,
      {DreamGuardSource source = DreamGuardSource.local}) {
    if (text == null || questionMarks(text) != 1) return null;
    final polished = polish(text, facts, source: source);
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
      if (token != null &&
          DreamGroundingWords.mentions(text, token, facts.language)) {
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
      facts.language,
    );
  }
}
