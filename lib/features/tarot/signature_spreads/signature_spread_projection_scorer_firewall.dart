/// Phase 5B — documentation: scorer does not yet consume Phase 5 edges.
library;

/// Phase 5B establishes deterministic structural semantics only.
///
/// The frozen Phase 3 relationship scorer resolves edge semantics from
/// `kAuthoritativePositionEdges` and does **not** consume Phase 5
/// Crossroads edges (`kSignatureCrossroadsEdges`).
///
/// Do not claim Crossroads edge-aware relationship scoring is live.
/// Future scorer integration requires a separately audited seam.
abstract final class SignatureSpreadProjectionScorerFirewall {
  SignatureSpreadProjectionScorerFirewall._();

  static const note =
      'Phase 3 scorer does not consume Phase 5 Crossroads edges (5B intentional).';
}
