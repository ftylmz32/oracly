/// Portrait voice gate. Char ceilings stay on the wire contract.
///
/// Full charts are asked for 400–550 words. The hard ceiling sits above that
/// target and below the 16 Oct 2026 captured report (~880 words). Thinner
/// scopes cannot be padded up to a full portrait. Ratio checks start only
/// once there is enough prose to measure; they use densities, not a word ban.
library;

import '../request/yildizname_narrative_scope.dart';
import '../result/yildizname_narrative_structured_result.dart';
import '../result/yildizname_result_error.dart';
import 'yildizname_quality_voice_anchors.dart';
import 'yildizname_quality_voice_life.dart';
import 'yildizname_quality_voice_scan.dart';

abstract final class YildiznameQualityVoice {
  YildiznameQualityVoice._();

  /// Above the writing target, below the captured report.
  static const fullWordCeiling = 640;
  static const reducedWordCeiling = 340;
  static const legacyWordCeiling = 220;

  /// Short contract fixtures stay under this and are not ratio-scored.
  static const ratioFloorWords = 220;

  static const sectionSprawlAt = 7;
  static const technicalRatio = 0.38;
  static const jargonPerHundred = 3.5;
  static const hedgeRatio = 0.45;

  static YildiznameVoiceReport inspect(
    YildiznameNarrativeScope scope,
    YildiznameNarrativeStructuredResult result,
  ) {
    final prose = result.visibleProse;
    final sentences = YildiznameVoiceScan.sentences(prose);
    final wordCount = YildiznameVoiceScan.words(prose);
    final jargon = YildiznameVoiceScan.jargonHits(prose);
    final technical = YildiznameVoiceScan.technicalSentences(sentences);
    final hedged = YildiznameVoiceScan.hedgedSentences(sentences);
    final piles = YildiznameVoiceScan.abstractPiles(sentences);
    final blocks = <String>[
      result.summary.text,
      for (final s in result.sections) s.text,
      result.closingMessage,
    ];
    final anchors = YildiznameVoiceAnchors.repeated(blocks);
    final life = YildiznameVoiceLife.inspect(result.summary.text, sentences);
    final findings = <String>[];
    if (wordCount > _ceiling(scope)) findings.add('length');
    if (result.sections.length >= sectionSprawlAt) {
      findings.add('sectionSprawl');
    }
    if (wordCount >= ratioFloorWords && sentences.isNotEmpty) {
      if (technical / sentences.length > technicalRatio) {
        findings.add('technicalCenter');
      }
      if (jargon * 100 / wordCount > jargonPerHundred) {
        findings.add('jargonDensity');
      }
      if (hedged / sentences.length > hedgeRatio) {
        findings.add('hedgeDensity');
      }
      if (anchors.length >= 2 && blocks.length >= 8) {
        findings.add('repetition');
      }
      if (piles >= 2) findings.add('abstractPile');
      if (YildiznameVoiceScan.reportOpening(result.summary.text)) {
        findings.add('reportOpening');
      }
    }
    if (life.inventedRoutines > 0) findings.add('inventedRoutine');
    if (life.literary) findings.add('literaryVoice');
    return YildiznameVoiceReport(
      words: wordCount,
      sentences: sentences.length,
      jargonHits: jargon,
      technicalSentences: technical,
      hedgedSentences: hedged,
      abstractPiles: piles,
      anchors: anchors,
      findings: findings,
    );
  }

  static void validate(
    YildiznameNarrativeScope scope,
    YildiznameNarrativeStructuredResult result,
  ) {
    final report = inspect(scope, result);
    if (report.findings.isEmpty) return;
    throw YildiznameResultException(
      YildiznameResultErrorKind.prose,
      'voice:${report.findings.join(',')}',
    );
  }

  static int _ceiling(YildiznameNarrativeScope scope) => switch (scope) {
        YildiznameNarrativeScope.legacy => legacyWordCeiling,
        YildiznameNarrativeScope.reduced => reducedWordCeiling,
        YildiznameNarrativeScope.full => fullWordCeiling,
      };
}

final class YildiznameVoiceReport {
  YildiznameVoiceReport({
    required this.words,
    required this.sentences,
    required this.jargonHits,
    required this.technicalSentences,
    required this.hedgedSentences,
    required this.abstractPiles,
    required List<String> anchors,
    required List<String> findings,
  })  : anchors = List.unmodifiable(anchors),
        findings = List.unmodifiable(findings);

  final int words;
  final int sentences;
  final int jargonHits;
  final int technicalSentences;
  final int hedgedSentences;
  final int abstractPiles;
  final List<String> anchors;
  final List<String> findings;

  @override
  String toString() =>
      'words=$words sentences=$sentences jargon=$jargonHits '
      'technical=$technicalSentences/$sentences hedged=$hedgedSentences '
      'piles=$abstractPiles anchors=$anchors findings=$findings';
}
