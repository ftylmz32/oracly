/// One free tarot-context OR turn. A signed-in account owns it; the server admits it.
library;

import '../../../core/auth/user_local_data_isolation.dart';
import '../../../core/data/datasources/local_storage.dart';
import '../../ai/oracle_conversation/models/oracle_reading_context.dart';

/// Local compose hint for one tarot handoff.
///
/// A committed account may open any tarot reading once. The server still
/// admits or rejects that turn. With no account on the device, only the
/// marked first-session card matches. Never unlocks generic OR, voice,
/// or a non-tarot handoff.
abstract final class FirstReadingOrDeepen {
  FirstReadingOrDeepen._();

  static const sessionKey = 'first_reading_or_deepen_session_id';
  static const consumedKey = 'first_reading_or_deepen_consumed';
  static const consumedOwnersKey = 'first_reading_or_deepen_consumed_owners';

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
    if (!_isTarot(context)) return false;
    final owner = _owner(storage);
    if (owner != null) return !_spent(storage, owner);
    if (isConsumed(storage)) return false;
    final eligible = eligibleSessionId(storage);
    if (eligible == null) return false;
    return context!.sessionId.trim() == eligible;
  }

  /// Mark consumed only after a usable assistant response for that context.
  static Future<bool> consumeIfActive(
    LocalStorage storage,
    OracleReadingContext? context,
  ) async {
    if (!allows(storage, context)) return false;
    final owner = _owner(storage);
    if (owner == null) {
      await storage.setBool(consumedKey, true);
      return true;
    }
    final next = {..._owners(storage), owner};
    await storage.setString(consumedOwnersKey, next.join('\n'));
    return true;
  }

  static bool _isTarot(OracleReadingContext? context) =>
      context != null && context.kind == OracleReadingKind.tarot;

  static String? _owner(LocalStorage storage) {
    final id = storage.getString(UserLocalDataIsolation.ownerKey)?.trim() ?? '';
    return id.isEmpty ? null : id;
  }

  static Set<String> _owners(LocalStorage storage) {
    final raw = storage.getString(consumedOwnersKey) ?? '';
    return raw
        .split('\n')
        .map((line) => line.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  /// A legacy device flag, with no owner list, belongs to the signed-in account.
  static bool _spent(LocalStorage storage, String owner) {
    final owners = _owners(storage);
    if (owners.contains(owner)) return true;
    return owners.isEmpty && isConsumed(storage);
  }
}
