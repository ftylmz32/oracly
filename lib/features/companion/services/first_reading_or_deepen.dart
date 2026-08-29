/// One free contextual OR deepen for the first-session Tarot reading.
library;

import '../../../core/data/datasources/local_storage.dart';
import '../../ai/oracle_conversation/models/oracle_reading_context.dart';

/// Durable allowance bound to the first-session Tarot [sessionId].
///
/// Free compose requires a live matching [OracleReadingContext] — never
/// unlocks generic OR, voice, or non-Tarot handoffs.
abstract final class FirstReadingOrDeepen {
  FirstReadingOrDeepen._();

  static const sessionKey = 'first_reading_or_deepen_session_id';
  static const consumedKey = 'first_reading_or_deepen_consumed';

  /// Call once when the first-session single-card Tarot session is created.
  static Future<void> markEligible(
    LocalStorage storage,
    String sessionId,
  ) async {
    final id = sessionId.trim();
    if (id.isEmpty) return;
    // Only the first first-session reading may own this allowance.
    final existing = storage.getString(sessionKey)?.trim() ?? '';
    if (existing.isNotEmpty) return;
    await storage.setString(sessionKey, id);
    await storage.setBool(consumedKey, false);
  }

  static String? eligibleSessionId(LocalStorage storage) {
    final id = storage.getString(sessionKey)?.trim() ?? '';
    return id.isEmpty ? null : id;
  }

  static bool isConsumed(LocalStorage storage) =>
      storage.getBool(consumedKey) == true;

  /// True when a free user may compose one text turn for [context].
  static bool allows(LocalStorage storage, OracleReadingContext? context) {
    if (context == null) return false;
    if (context.kind != OracleReadingKind.tarot) return false;
    if (isConsumed(storage)) return false;
    final eligible = eligibleSessionId(storage);
    if (eligible == null) return false;
    return context.sessionId.trim() == eligible;
  }

  /// Mark consumed only after a usable assistant response for that context.
  static Future<bool> consumeIfActive(
    LocalStorage storage,
    OracleReadingContext? context,
  ) async {
    if (!allows(storage, context)) return false;
    await storage.setBool(consumedKey, true);
    return true;
  }
}
