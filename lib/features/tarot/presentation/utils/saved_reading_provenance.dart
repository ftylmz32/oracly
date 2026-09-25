/// Parses persisted presentation provenance strings (Phase 7F).
library;

import '../../interpretation/models/interpretation_result.dart';
import '../widgets/ai_reading/ai_reading_content.dart';

abstract final class SavedReadingProvenance {
  SavedReadingProvenance._();

  static InterpretationSource? parseSource(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return InterpretationSource.values.asNameMap()[raw.trim()];
  }

  static TarotReadingDeliveryKind? parseDelivery(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return TarotReadingDeliveryKind.values.asNameMap()[raw.trim()];
  }
}
