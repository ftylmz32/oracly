/// Phase 3 — next evidence acquisition need / planner.
library;

import 'birth_evidence.dart';

enum BirthEvidenceAcquisitionNeed {
  birthDate,
  timeKnowledge,
  birthTime,
  birthPlace,
  none,
}

abstract final class BirthEvidenceAcquisitionPlan {
  BirthEvidenceAcquisitionPlan._();

  /// Next meaningful ask. Honors prior unknown/place-skip choices.
  static BirthEvidenceAcquisitionNeed nextNeed(BirthEvidence e) {
    if (!e.hasDate) return BirthEvidenceAcquisitionNeed.birthDate;
    // timeKnown defaults false; onboarding must set an explicit choice.
    // Persisted profiles always have birthTimeKnown set after first save.
    // Use a sentinel: if date exists but we never answered time — detect via
    // optional external flag. For BirthEvidence, callers pass timeAnswered.
    return BirthEvidenceAcquisitionNeed.none;
  }

  /// Prefer this when UI can distinguish unanswered time knowledge.
  static BirthEvidenceAcquisitionNeed nextNeedWithTimeAnswered(
    BirthEvidence e, {
    required bool timeKnowledgeAnswered,
  }) {
    if (!e.hasDate) return BirthEvidenceAcquisitionNeed.birthDate;
    if (!timeKnowledgeAnswered) {
      return BirthEvidenceAcquisitionNeed.timeKnowledge;
    }
    if (e.timeKnown && e.birthTime == null) {
      return BirthEvidenceAcquisitionNeed.birthTime;
    }
    final placeMissing = !e.hasValidPlaceEvidence;
    if (placeMissing && !e.birthPlaceUnknownConfirmed) {
      return BirthEvidenceAcquisitionNeed.birthPlace;
    }
    return BirthEvidenceAcquisitionNeed.none;
  }

  /// For persisted profiles: time knowledge was answered at save time.
  static BirthEvidenceAcquisitionNeed nextNeedPersisted(BirthEvidence e) {
    return nextNeedWithTimeAnswered(e, timeKnowledgeAnswered: true);
  }
}
