/// Optional daily astrology writer capability — structured result map.
library;

import 'ai_outcome.dart';

/// Implemented by the production proxy service only.
abstract class OraclyAstrologyDailyAiService {
  /// [operationId] is the per-day, per-facts idempotency key; the server
  /// stores the delivered body under it and replays it for the same day.
  Future<AiOutcome<Map<String, dynamic>>> generateAstrologyDaily({
    required Map<String, dynamic> payload,
    required String operationId,
  });
}
