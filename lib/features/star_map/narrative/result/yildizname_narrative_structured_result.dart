/// Immutable structured Narrative V1 result.
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
  final YildiznameNarrativeBlock reflectionPrompt;
  final YildiznameNarrativeBlock closingMessage;

  Iterable<String> get allFactRefs sync* {
    yield* summary.factRefs;
    yield* reflectionPrompt.factRefs;
    yield* closingMessage.factRefs;
    for (final s in sections) {
      yield* s.factRefs;
    }
  }

  Iterable<String> get allThemeRefs sync* {
    yield* summary.themeRefs;
    yield* reflectionPrompt.themeRefs;
    yield* closingMessage.themeRefs;
    for (final s in sections) {
      yield* s.themeRefs;
    }
  }

  String get visibleProse {
    final b = StringBuffer()
      ..writeln(summary.text)
      ..writeln(reflectionPrompt.text)
      ..writeln(closingMessage.text);
    for (final s in sections) {
      b.writeln(s.text);
    }
    return b.toString();
  }
}
