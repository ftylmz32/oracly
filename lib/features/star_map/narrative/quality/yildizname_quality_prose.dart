/// Prose quality — JSON leak, machine refs, AI voice, repetition, genericity.
library;

import '../request/yildizname_narrative_request.dart';
import '../result/yildizname_narrative_structured_result.dart';
import '../result/yildizname_result_error.dart';
import '../result/yildizname_section_kind.dart';

abstract final class YildiznameQualityProse {
  YildiznameQualityProse._();

  static final _machine = <RegExp>[
    RegExp(r'\{[\s\n]*"', multiLine: true),
    RegExp(r'```'),
    RegExp(r'\bplacement\.(sun|moon|mercury)\b', caseSensitive: false),
    RegExp(r'\bangle\.(ascendant|midheaven)\b', caseSensitive: false),
    RegExp(r'\bfactRef\b', caseSensitive: false),
    RegExp(r'\bthemeRef\b', caseSensitive: false),
    RegExp(r'\bas an AI\b', caseSensitive: false),
    RegExp(r'\baccording to the prompt\b', caseSensitive: false),
    RegExp(r'\bTODO\b'),
    RegExp(r'\b\[INSERT'),
    RegExp(r'\{\{'),
  ];

  static final _generic = <RegExp>[
    RegExp(r'\bevren sana diyor', caseSensitive: false),
    RegExp(r'\byıldızlar kesin olarak', caseSensitive: false),
    RegExp(r'\bcosmic energy guarantees', caseSensitive: false),
    RegExp(r'\bthe stars have spoken\b', caseSensitive: false),
  ];

  static void validate(
    YildiznameNarrativeRequest request,
    YildiznameNarrativeStructuredResult result,
  ) {
    final prose = result.visibleProse;
    for (final re in _machine) {
      if (re.hasMatch(prose)) {
        throw YildiznameResultException(
          YildiznameResultErrorKind.prose,
          re.pattern,
        );
      }
    }
    for (final re in _generic) {
      if (re.hasMatch(prose)) {
        throw YildiznameResultException(
          YildiznameResultErrorKind.genericity,
          re.pattern,
        );
      }
    }
    _rejectRepetition(result);
    _rejectThemelessArchive(request, result);
  }

  static void _rejectRepetition(YildiznameNarrativeStructuredResult result) {
    final texts = <String>[
      result.summary.text.trim().toLowerCase(),
      result.closingMessage.text.trim().toLowerCase(),
      for (final s in result.sections) s.text.trim().toLowerCase(),
    ];
    final seen = <String>{};
    for (final t in texts) {
      if (t.isEmpty) continue;
      if (!seen.add(t)) {
        throw YildiznameResultException(
          YildiznameResultErrorKind.prose,
          'duplicateParagraph',
        );
      }
    }
    if (result.summary.text.trim().toLowerCase() ==
        result.closingMessage.text.trim().toLowerCase()) {
      throw YildiznameResultException(
        YildiznameResultErrorKind.prose,
        'summaryEqualsClosing',
      );
    }
  }

  static void _rejectThemelessArchive(
    YildiznameNarrativeRequest request,
    YildiznameNarrativeStructuredResult result,
  ) {
    if (request.discoveryThemes.isNotEmpty) return;
    for (final s in result.sections) {
      if (s.kind != YildiznameSectionKind.archiveEcho) continue;
      final t = s.text.toLowerCase();
      if (t.contains('tekrar') ||
          t.contains('recurring') ||
          t.contains('повтор') ||
          t.contains('history') ||
          t.contains('geçmiş okuma')) {
        throw YildiznameResultException(
          YildiznameResultErrorKind.themeRef,
          'archiveWithoutThemes',
        );
      }
    }
  }
}
