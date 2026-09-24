/// Phase 6D — Narrative V2 proxy wire payload (NOT live-wired).
library;

import '../prompt/narrative_tarot_prompt_canonical.dart';
import '../prompt/narrative_tarot_prompt_input.dart';

/// Exact external field names locked in Phase 6D.
abstract final class NarrativeTarotWireContract {
  NarrativeTarotWireContract._();

  static const mode = 'narrative_v2';
  static const contractVersion = 1;

  /// Builds proxy `payload` only — never includes session/reading/owner ids.
  static Map<String, Object?> payloadFor(NarrativeTarotPromptInput input) {
    return <String, Object?>{
      'mode': mode,
      'contractVersion': contractVersion,
      'language': input.languageCode,
      'narrative': NarrativeTarotPromptCanonical.toMap(input),
    };
  }
}
