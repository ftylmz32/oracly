/// Narrative section / summary block with evidence refs.
library;

import 'yildizname_section_kind.dart';

final class YildiznameNarrativeBlock {
  YildiznameNarrativeBlock({
    required this.text,
    required List<String> factRefs,
    required List<String> themeRefs,
  })  : factRefs = List.unmodifiable(factRefs),
        themeRefs = List.unmodifiable(themeRefs);

  final String text;
  final List<String> factRefs;
  final List<String> themeRefs;
}

final class YildiznameNarrativeSection {
  YildiznameNarrativeSection({
    required this.kind,
    required this.text,
    required List<String> factRefs,
    required List<String> themeRefs,
  })  : factRefs = List.unmodifiable(factRefs),
        themeRefs = List.unmodifiable(themeRefs);

  final YildiznameSectionKind kind;
  final String text;
  final List<String> factRefs;
  final List<String> themeRefs;
}
