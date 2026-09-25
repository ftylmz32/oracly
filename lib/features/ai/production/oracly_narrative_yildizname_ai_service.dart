/// Optional Yıldızname Narrative V1 capability — structured Result Contract.
library;

import 'ai_outcome.dart';

/// Implemented by production OpenAI proxy service only.
abstract class OraclyNarrativeYildiznameAiService {
  /// Returns the proxy Result Contract map (not legacy `{text}`).
  ///
  /// [attempt] is transport/idempotency metadata only (1 or 2).
  /// It must never enter the Narrative request body or provider prompt.
  Future<AiOutcome<Map<String, dynamic>>> generateNarrativeYildiznameReading({
    required Map<String, dynamic> payload,
    required String fingerprint,
    int attempt = 1,
  });
}
