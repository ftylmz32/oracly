/// Owner-checked display-name write. Only the two name keys.
library;

import '../../auth/user_local_data_isolation.dart';
import '../datasources/local_storage.dart';
import '../datasources/storage_result.dart';

/// Persists [name] to the canonical display-name keys.
///
/// The whole pair runs inside [UserLocalDataIsolation.runOwnerScopedMutation],
/// the same gate as an account switch. [stillOwner] is the owner captured
/// before waiting for that gate, and it is read again before every mutation
/// once the gate is held. A switch that already committed the next owner
/// therefore performs no write and no rollback.
Future<void> renameProfileDisplayName(
  LocalStorage storage, {
  required String name,
  required String profileNameKey,
  required String userNameKey,
  required bool Function() stillOwner,
}) {
  return UserLocalDataIsolation.runOwnerScopedMutation(() async {
    if (!stillOwner()) return;
    final previousName = storage.getString(profileNameKey) ?? '';
    final previousUserName = storage.getString(userNameKey);
    if (!stillOwner()) return;
    try {
      await storage
          .setString(profileNameKey, name)
          .requireDurable(profileNameKey);
    } catch (_) {
      if (!stillOwner()) return;
      rethrow;
    }
    if (!stillOwner()) return;
    try {
      await storage.setString(userNameKey, name).requireDurable(userNameKey);
    } catch (_) {
      if (!stillOwner()) return;
      await _restoreNames(
        storage,
        profileNameKey: profileNameKey,
        userNameKey: userNameKey,
        previousName: previousName,
        previousUserName: previousUserName,
        stillOwner: stillOwner,
      );
      throw StateError('profile display name was not durable');
    }
  });
}

Future<void> _restoreNames(
  LocalStorage storage, {
  required String profileNameKey,
  required String userNameKey,
  required String previousName,
  required String? previousUserName,
  required bool Function() stillOwner,
}) async {
  if (!stillOwner()) return;
  await storage
      .setString(profileNameKey, previousName)
      .requireDurable(profileNameKey);
  if (!stillOwner()) return;
  if (previousUserName == null) {
    if (storage.getString(userNameKey) == null) return;
    await storage.remove(userNameKey).requireDurable(userNameKey);
    return;
  }
  await storage
      .setString(userNameKey, previousUserName)
      .requireDurable(userNameKey);
}
