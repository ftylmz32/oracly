/// Presentation-safe Yıldızname result semantics.
///
/// These enums are UI semantics, not wire values. Never render `.name`.
library;

/// Where a result comes from — decided by the caller, never inferred from copy.
enum YildiznameResultSource {
  legacyLive,
  legacyArtifact,
  narrativeLive,
  narrativeArtifact;

  bool get isArtifact =>
      this == YildiznameResultSource.legacyArtifact ||
      this == YildiznameResultSource.narrativeArtifact;

  bool get isNarrative =>
      this == YildiznameResultSource.narrativeLive ||
      this == YildiznameResultSource.narrativeArtifact;
}

/// How much birth evidence a reading may honestly claim.
///
/// Ordered from lightest to richest; resolution only ever moves DOWN.
enum YildiznameResultScope {
  legacy,
  reduced,
  full;

  int get rank => index;

  static YildiznameResultScope ofRank(int rank) {
    if (rank <= 0) return YildiznameResultScope.legacy;
    if (rank == 1) return YildiznameResultScope.reduced;
    return YildiznameResultScope.full;
  }
}

/// Semantic role of a result block — lets later phases style roles apart.
enum YildiznameSectionRole { summary, chapter, reflection, closing }
