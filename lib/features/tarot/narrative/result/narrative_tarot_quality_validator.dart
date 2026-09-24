/// Phase 6D — client evidence/quality re-validation of structured results.
library;

import '../evidence/narrative_request.dart';
import 'narrative_tarot_prose_quality.dart';
import 'narrative_tarot_quality_evidence.dart';
import 'narrative_tarot_quality_privacy.dart';
import 'narrative_tarot_result_error.dart';
import 'narrative_tarot_structured_result.dart';

abstract final class NarrativeTarotQualityValidator {
  NarrativeTarotQualityValidator._();

  static void validate({
    required TarotNarrativeRequest request,
    required NarrativeTarotStructuredResult result,
  }) {
    if (result.languageCode != request.languageCode) {
      throw NarrativeTarotResultException(
        NarrativeTarotResultErrorKind.locale,
        'languageCode',
      );
    }
    validateCardCoverage(request, result);
    validateRelationships(request, result);
    validateRecurrence(request, result);
    validateMemory(request, result);
    rejectPrivateLeaks(request, result);
    NarrativeTarotProseQuality.validate(result);
  }
}
