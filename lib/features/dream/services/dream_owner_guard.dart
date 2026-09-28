/// Dream owner snapshot — canonical local owner + switch epoch + clear tick.
library;

import 'package:flutter/foundation.dart';

import '../../../core/auth/user_local_data_isolation.dart';
import '../../../core/data/datasources/local_storage.dart';

/// Captured once when an analyze/reinterpret starts; compared before and
/// after every durable Dream write. The owner string alone cannot detect an
/// A→B→A round trip — [epoch] can.
@immutable
final class DreamOwnerSnapshot {
  const DreamOwnerSnapshot({
    required this.ownerId,
    required this.epoch,
    required this.clearGeneration,
  });

  final String ownerId;
  final int epoch;
  final int clearGeneration;

  bool get isValid => ownerId.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is DreamOwnerSnapshot &&
      other.ownerId == ownerId &&
      other.epoch == epoch &&
      other.clearGeneration == clearGeneration;

  @override
  int get hashCode => Object.hash(ownerId, epoch, clearGeneration);
}

/// Thrown when the owner context changed (switch, sign-out, deletion, or a
/// Dream privacy clear) while an operation was in flight, or when a dream
/// being reinterpreted no longer belongs to the current owner's storage.
/// Nothing from the operation is persisted or displayed.
final class DreamOwnerChangedException implements Exception {
  const DreamOwnerChangedException();

  @override
  String toString() => 'DreamOwnerChangedException';
}

class DreamOwnerGuard {
  DreamOwnerGuard({required this._ownerId});

  /// Reads [UserLocalDataIsolation.ownerKey] — the one local owner authority.
  factory DreamOwnerGuard.fromStorage(LocalStorage storage) => DreamOwnerGuard(
        ownerId: () => storage.getString(UserLocalDataIsolation.ownerKey),
      );

  final String? Function() _ownerId;

  static int _clearGeneration = 0;

  /// Discovery-history clear bumps this first, so an analysis already in
  /// flight for the same owner cannot re-persist cleared Dream data.
  static void markCleared() => _clearGeneration++;

  static int get clearGeneration => _clearGeneration;

  DreamOwnerSnapshot capture() => DreamOwnerSnapshot(
        ownerId: _ownerId()?.trim() ?? '',
        epoch: UserLocalDataIsolation.accountSwitchEpoch.value,
        clearGeneration: _clearGeneration,
      );

  bool stillValid(DreamOwnerSnapshot snapshot) =>
      snapshot.isValid && capture() == snapshot;
}
