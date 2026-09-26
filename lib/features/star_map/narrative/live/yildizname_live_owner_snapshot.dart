/// Phase 8B — owner + account-switch epoch snapshot for Narrative transactions.
library;

import 'package:flutter/foundation.dart';

import '../../../../core/auth/user_local_data_isolation.dart';
import '../../../../core/data/datasources/local_storage.dart';

@immutable
final class YildiznameLiveOwnerSnapshot {
  const YildiznameLiveOwnerSnapshot({
    required this.ownerId,
    required this.epoch,
  });

  final String ownerId;
  final int epoch;

  bool get isValid => ownerId.isNotEmpty;

  static YildiznameLiveOwnerSnapshot capture(LocalStorage storage) {
    final owner = storage.getString(UserLocalDataIsolation.ownerKey)?.trim() ?? '';
    return YildiznameLiveOwnerSnapshot(
      ownerId: owner,
      epoch: UserLocalDataIsolation.accountSwitchEpoch.value,
    );
  }

  bool matches(LocalStorage storage) {
    final now = capture(storage);
    return now.ownerId == ownerId && now.epoch == epoch;
  }
}
