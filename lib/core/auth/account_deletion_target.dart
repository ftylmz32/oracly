/// Durable binding of a deletion lifecycle to the ORIGINAL Firebase uid.
library;

import '../data/datasources/local_storage.dart';
import 'auth_service.dart';
import 'user_local_data_isolation.dart';

/// Provenance for account-deletion markers — never authorize destructive
/// work from boolean markers alone.
abstract final class AccountDeletionTarget {
  AccountDeletionTarget._();

  static const targetUidKey = 'account_deletion_target_uid';
  static const bootstrapUidKey = 'account_deletion_bootstrap_uid';

  /// Valid non-blank stored target uid, or null when absent/corrupt/blank.
  static String? readTargetUid(LocalStorage storage) {
    final raw = storage.peek(targetUidKey);
    if (raw == null) return null;
    if (raw is! String) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// True when a string target is durably present and non-blank.
  static bool hasValidTarget(LocalStorage storage) =>
      readTargetUid(storage) != null;

  /// Wrong-type / blank string while a key exists — corrupt.
  static bool isTargetCorrupt(LocalStorage storage) {
    final raw = storage.peek(targetUidKey);
    if (raw == null) return false;
    if (raw is! String) return true;
    return raw.trim().isEmpty;
  }

  static String? readBootstrapUid(LocalStorage storage) {
    final raw = storage.peek(bootstrapUidKey);
    if (raw == null) return null;
    if (raw is! String) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Wrong-type / blank string while a key exists — corrupt. Mirrors
  /// [isTargetCorrupt] for the bootstrap provenance key.
  static bool isBootstrapCorrupt(LocalStorage storage) {
    final raw = storage.peek(bootstrapUidKey);
    if (raw == null) return false;
    if (raw is! String) return true;
    return raw.trim().isEmpty;
  }

  /// Persist [uid] and verify the durable read-back.
  static Future<bool> persistTarget(LocalStorage storage, String uid) async {
    final trimmed = uid.trim();
    if (trimmed.isEmpty) return false;
    if (!await storage.setString(targetUidKey, trimmed)) return false;
    return readTargetUid(storage) == trimmed;
  }

  static Future<bool> persistBootstrap(LocalStorage storage, String uid) async {
    final trimmed = uid.trim();
    if (trimmed.isEmpty) return false;
    if (!await storage.setString(bootstrapUidKey, trimmed)) return false;
    return readBootstrapUid(storage) == trimmed;
  }

  static Future<bool> clearTarget(LocalStorage storage) async {
    if (!await storage.remove(targetUidKey)) return false;
    return readTargetUid(storage) == null && !isTargetCorrupt(storage);
  }

  static Future<bool> clearBootstrap(LocalStorage storage) async {
    if (!await storage.remove(bootstrapUidKey)) return false;
    return readBootstrapUid(storage) == null;
  }

  /// Legacy installs: marker true without target. Bind ONLY when
  /// [ownerKey] and live [AuthService.currentUserId] both equal the same
  /// non-empty uid. Never attach an old marker to a different identity.
  static Future<bool> tryMigrateLegacyTarget({
    required LocalStorage storage,
    required AuthService auth,
  }) async {
    if (hasValidTarget(storage)) return true;
    if (isTargetCorrupt(storage)) return false;
    final owner = storage.getString(UserLocalDataIsolation.ownerKey)?.trim();
    final live = auth.currentUserId?.trim();
    if (owner == null || owner.isEmpty) return false;
    if (live == null || live.isEmpty) return false;
    if (owner != live) return false;
    return persistTarget(storage, owner);
  }

  /// Current Firebase uid must equal the deletion target for phases that
  /// still operate on the OLD identity.
  static bool currentMatchesTarget({
    required LocalStorage storage,
    required AuthService auth,
  }) {
    final target = readTargetUid(storage);
    final live = auth.currentUserId?.trim();
    if (target == null || live == null || live.isEmpty) return false;
    return live == target;
  }

  /// Retires leftover target/bootstrap provenance ONLY when the caller has
  /// already proven no deletion phase marker is durably true (and neither
  /// key is corrupt) — i.e. this provenance is orphaned residue from a
  /// crash that happened either before any destructive work began
  /// (`persistTarget` succeeded, then the next durable write never landed)
  /// or after every destructive step already fully completed (finalization
  /// reached the point of clearing this same provenance, then crashed
  /// before the LAST durable gate marker was retired). Never authorizes
  /// destructive work itself — only clears bookkeeping keys once proven
  /// harmless by the caller.
  static Future<bool> reconcileHarmlessOrphan(LocalStorage storage) async {
    if (!await clearTarget(storage)) return false;
    if (!await clearBootstrap(storage)) return false;
    return true;
  }
}
