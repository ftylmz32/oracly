/// Optional Narrative Tarot V2 capability — structured Result Contract reply.
library;

import 'ai_outcome.dart';

/// Implemented by production OpenAI proxy service only.
abstract class OraclyNarrativeTarotAiService {
  /// Returns the proxy Result Contract V2 map (not legacy `{text}`).
  Future<AiOutcome<Map<String, dynamic>>> generateNarrativeTarotReading({
    required Map<String, dynamic> payload,
    required String fingerprint,
  });
}
