/// `LocalStorage` mutations return `Future<bool>` — the underlying
/// `SharedPreferences` write/remove can resolve to `false` WITHOUT ever
/// throwing. Safety-critical callers (account wipe, isolation, deletion
/// markers, sign-out) must treat that `false` exactly like a thrown
/// exception, never like success. This is the one place that conversion
/// happens, so it can never be silently forgotten at a call site.
library;

extension RequireStorageResult on Future<bool> {
  /// Awaits this mutation and throws if it resolves to `false`. Designed to
  /// be used inside code that already treats a thrown exception as a
  /// failure (e.g. a try/catch-per-step wipe loop) — converting `false`
  /// into a throw lets that existing failure-handling catch it too, instead
  /// of needing a second, parallel bool-checking path at every call site.
  Future<void> requireDurable([String? label]) async {
    if (!await this) {
      throw StateError(
        'LocalStorage mutation did not durably succeed'
        '${label != null ? ' ($label)' : ''}',
      );
    }
  }
}
