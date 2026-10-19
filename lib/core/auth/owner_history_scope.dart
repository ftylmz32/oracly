/// Binds a fortune write to the owner who started it.
library;

import 'dart:async';

import '../data/datasources/local_storage.dart';
import 'user_local_data_isolation.dart';

/// The account changed before a fortune row could be stored.
final class OwnerHistoryRejected implements Exception {
  const OwnerHistoryRejected();
}

/// Zone captured when a reading starts. The store checks it inside the
/// same lock as account wipe, so a late result cannot land on the next account.
abstract final class OwnerHistoryScope {
  static const _owner = #oraclyOwnerHistoryOwner;
  static const _epoch = #oraclyOwnerHistoryEpoch;

  static Future<T> bind<T>({
    required String ownerId,
    required int epoch,
    required Future<T> Function() body,
  }) {
    return runZoned(body, zoneValues: {_owner: ownerId, _epoch: epoch});
  }

  static String? get ownerId => Zone.current[_owner] as String?;

  static int? get epoch => Zone.current[_epoch] as int?;

  /// [ownerId] and [epoch] were captured before the provider wait.
  static Future<void> commitBound({
    required String ownerId,
    required int epoch,
    required Future<bool> Function() save,
  }) async {
    final wrote = await bind(ownerId: ownerId, epoch: epoch, body: save);
    if (!wrote) throw const OwnerHistoryRejected();
  }

  static Future<bool> commit({
    required LocalStorage storage,
    required Future<void> Function() write,
  }) {
    return UserLocalDataIsolation.runOwnerScopedMutation(() async {
      final expectedOwner = ownerId;
      final expectedEpoch = epoch;
      if (expectedOwner != null || expectedEpoch != null) {
        final current =
            storage.getString(UserLocalDataIsolation.ownerKey)?.trim() ?? '';
        if (expectedOwner != null && current != expectedOwner) return false;
        if (expectedEpoch != null &&
            UserLocalDataIsolation.accountSwitchEpoch.value != expectedEpoch) {
          return false;
        }
      }
      await write();
      return true;
    });
  }
}
