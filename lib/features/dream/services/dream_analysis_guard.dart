/// Reject dictionary, medical, certainty, and invented dream images.
library;

import '../../../core/copy/fortune_voice.dart';
import '../../../core/reading/human_reader.dart';
import '../../../core/reading/ai_output_quality_gate.dart';
import '../../../core/reading/ai_output_quality_kind.dart';
import '../../content/dream/data/dream_symbol_catalogue.dart';
import 'dream_analysis_facts.dart';

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

  static String? oneQuestion(String? text, DreamAnalysisFacts facts) {
    if (text == null) return null;
    final guarded = HumanReader.guard(text.trim());
    if (!guarded.contains('?')) return null;
    final q = guarded.split('?').first.trim();
    if (q.isEmpty) return null;
    final ask = '$q?';
    if (looksDictionary(ask) || FortuneVoice.claimsMedical(ask)) return null;
    if (facts.told.isNotEmpty && !_touchesTold(ask, facts)) return null;
    if (ask.contains('\n')) return null;
    return ask;
  }

  static bool _touchesTold(String text, DreamAnalysisFacts facts) {
    final lower = text.toLowerCase();
    for (final token in [
      facts.image,
      facts.companion,
      facts.place,
      facts.person,
      facts.emotion,
      facts.tag,
    ]) {
      if (token != null && lower.contains(token.toLowerCase())) return true;
    }
    final scene = facts.scene.toLowerCase();
    if (scene.length >= 8) {
      final word = scene.split(' ').where((w) => w.length >= 4).firstOrNull;
      if (word != null && lower.contains(word)) return true;
    }
    return false;
  }

  static bool _inventsImage(String text, DreamAnalysisFacts facts) {
    final lower = text.toLowerCase();
    final told = facts.told.toLowerCase();
    for (final item in DreamSymbolCatalogue.all) {
      final tr = item.tokenTr.toLowerCase();
      final en = item.token.toLowerCase();
      final inText = lower.contains(tr) || lower.contains(en);
      if (!inText) continue;
      if (told.contains(tr) || told.contains(en)) continue;
      return true;
    }
    return false;
  }
}
