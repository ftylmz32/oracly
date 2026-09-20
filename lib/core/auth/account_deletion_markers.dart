/// Type-safe reads for the durable account-deletion gate markers.
///
/// [LocalStorage.getBool] returns null both when a key is genuinely absent
/// AND when it holds a value of the wrong type (a legacy/corrupt row) — this
/// project has already hit that exact ambiguity for real with upgraded-
/// install Tarot prefs. For an ordinary preference, collapsing both cases to
/// "unset" is a reasonable default. For a SAFETY gate deciding whether an
/// interrupted account deletion may be treated as resolved, it is not: a
/// present-but-corrupt marker must never read the same as "no marker at
/// all". This is the one place both [AccountDeletionPendingState] and
/// [AccountDeletionService] read these markers, so there is exactly one
/// definition of "safe to treat as clear".
library;

import '../data/datasources/local_storage.dart';

enum MarkerRead { absent, isFalse, isTrue, corrupt }

abstract final class AccountDeletionMarkers {
  AccountDeletionMarkers._();

  static MarkerRead read(LocalStorage storage, String key) {
    final raw = storage.peek(key);
    if (raw == null) return MarkerRead.absent;
    if (raw is bool) return raw ? MarkerRead.isTrue : MarkerRead.isFalse;
    return MarkerRead.corrupt;
  }

  /// True for both a real `true` and a corrupt (wrong-type) value — a
  /// marker this can't prove is safe must never be treated as clear.
  static bool isPendingOrCorrupt(LocalStorage storage, String key) {
    final result = read(storage, key);
    return result == MarkerRead.isTrue || result == MarkerRead.corrupt;
  }
}
