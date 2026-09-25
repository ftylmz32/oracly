/// Phase 3 — deterministic E0–E4 classifier (production).
library;

import 'birth_evidence.dart';
import 'birth_evidence_completeness.dart';

abstract final class BirthEvidenceClassifier {
  BirthEvidenceClassifier._();

  static BirthEvidenceCompleteness classify(BirthEvidence e) {
    if (!e.hasDate) return BirthEvidenceCompleteness.missingDate;
    if (e.hasKnownTime && e.hasValidPlaceEvidence) {
      return BirthEvidenceCompleteness.full;
    }
    if (e.hasKnownTime) return BirthEvidenceCompleteness.dateAndTimeNoPlace;
    if (e.hasValidPlaceEvidence) {
      return BirthEvidenceCompleteness.dateAndPlaceNoTime;
    }
    return BirthEvidenceCompleteness.dateOnly;
  }
}
