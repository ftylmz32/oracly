/// Owner-checked display-name write. Only the two name keys.
library;

import '../datasources/local_storage.dart';
import '../datasources/storage_result.dart';

/// Persists [name] to the canonical display-name keys.
///
/// [stillOwner] is read immediately before every mutation. Once it is false
/// the operation stops, including rollback, so a rename that started under
/// the previous owner cannot write into the next owner's storage.
Future<void> renameProfileDisplayName(
  LocalStorage storage, {
  required String name,
  required String profileNameKey,
  required String userNameKey,
  required bool Function() stillOwner,
}) async {
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
