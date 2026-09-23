/// Memory evidence shells — empty in Phase 3D.1 (Phase 4 fills later).
library;

enum MemoryEvidenceKind { memorySummary, revisitExcerpt, revisitInstruction }

class MemoryEvidenceEntry {
  const MemoryEvidenceEntry({
    required this.evidenceRef,
    required this.kind,
    required this.contentForModel,
  });

  final String evidenceRef;
  final MemoryEvidenceKind kind;
  final String contentForModel;
}

class TarotNarrativeMemoryEvidence {
  const TarotNarrativeMemoryEvidence({
    required this.entries,
    required this.priorReadingCount,
    required this.recentCardNames,
    required this.recurringThemeLabels,
    required this.included,
    required this.omitReason,
  });

  final List<MemoryEvidenceEntry> entries;
  final int priorReadingCount;

  /// Migration hint only — never authorizes recurrence claims.
  final List<String> recentCardNames;

  /// Migration hint only — never authorizes recurrence claims.
  final List<String> recurringThemeLabels;
  final bool included;
  final String omitReason;

  /// Safe empty shell for Phase 3D.1.
  static const empty = TarotNarrativeMemoryEvidence(
    entries: [],
    priorReadingCount: 0,
    recentCardNames: [],
    recurringThemeLabels: [],
    included: false,
    omitReason: 'empty',
  );
}
