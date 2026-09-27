/// Immutable structured Narrative V1 result — the FROZEN Phase 5 shape:
/// `summary` and `sections` are evidence-bearing blocks; `reflectionPrompt`
/// (nullable) and `closingMessage` are plain strings that own no refs.
library;

import '../request/yildizname_narrative_scope.dart';
import 'yildizname_narrative_section.dart';

final class YildiznameNarrativeStructuredResult {
  YildiznameNarrativeStructuredResult({
    required this.contractVersion,
    required this.languageCode,
    required this.scope,
    required this.summary,
    required List<YildiznameNarrativeSection> sections,
    required this.reflectionPrompt,
    required this.closingMessage,
  }) : sections = List.unmodifiable(sections);

  final int contractVersion;
  final String languageCode;
  final YildiznameNarrativeScope scope;
  final YildiznameNarrativeBlock summary;
  final List<YildiznameNarrativeSection> sections;
  /// `null` when the writer chose no reflection prompt.
  final String? reflectionPrompt;
  final String closingMessage;

  /// Refs come ONLY from the blocks that own them (summary + sections).
  Iterable<String> get allFactRefs sync* {
    yield* summary.factRefs;
    for (final s in sections) {
      yield* s.factRefs;
    }
  }

  Iterable<String> get allThemeRefs sync* {
    yield* summary.themeRefs;
    for (final s in sections) {
      yield* s.themeRefs;
    }
  }

  String get visibleProse {
    final b = StringBuffer()..writeln(summary.text);
    for (final s in sections) {
      b.writeln(s.text);
    }
    final reflection = reflectionPrompt;
    if (reflection != null && reflection.trim().isNotEmpty) {
      b.writeln(reflection);
    }
    b.writeln(closingMessage);
    return b.toString();
  }
}
