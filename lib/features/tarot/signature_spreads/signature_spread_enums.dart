/// Phase 5 — Signature Spread owned enums (not Phase 3).
library;

/// Product/UI geometry. Never added to frozen [NarrativeGeometryHook].
enum SignatureGeometryHook {
  single,
  threeLinear,
  fiveLinear,
  fiveDecision,
}

/// Historical memory inclusion posture for signature products.
enum SignatureMemoryInclusionPosture {
  normal,
  reduced,
  none,
}

/// Phase 5 length/depth metadata (does not modify NarrativeLengthBand).
enum SignatureLengthBand {
  short,
  medium,
  deep,
}
