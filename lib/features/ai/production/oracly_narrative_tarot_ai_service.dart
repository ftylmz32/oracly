/// Optional Narrative Tarot V2 capability — structured Result Contract reply.
library;

import 'ai_outcome.dart';

/// Implemented by production OpenAI proxy service only.
abstract class OraclyNarrativeTarotAiService {
  /// Returns the proxy Result Contract V2 map (not legacy `{text}`).
  ///
  /// [attempt] is transport/idempotency metadata only (1 or 2).
  /// It must never enter the Narrative request body or provider prompt.
  Future<AiOutcome<Map<String, dynamic>>> generateNarrativeTarotReading({
    required Map<String, dynamic> payload,
    required String fingerprint,
    int attempt = 1,
  });
}
