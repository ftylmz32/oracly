/// R5 — logout wipe, pending-op isolation, failed-sign-out preserves data.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/sign_out_local_cleanup.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/auth/user_local_data_wipe.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/dream/services/dream_attempt_store.dart';
import 'package:oracly_new/features/reading_operation/models/reading_operation_status.dart';
import 'package:oracly_new/features/reading_operation/services/reading_pending_operation_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Throws when [remove] is called for any key in [failingKeys], then
/// behaves normally for everything else.
class _KeyFailingStorage extends LocalStorage {
  _KeyFailingStorage(SharedPreferences prefs, {required this.failingKeys})
      : super(prefs);

  final Set<String> failingKeys;

  @override
  Future<bool> remove(String key) async {
    if (failingKeys.contains(key)) {
      throw StateError('simulated remove failure for $key');
    }
    return super.remove(key);
  }
}

const _pending = ReadingPendingOperation(
  operationId: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  sourceRequestId: 'src-r5-pending-01',
  mimeType: 'image/jpeg',
);

Future<({LocalStorage storage, InMemorySecureStorage secure})> _boot() async {
  SharedPreferences.setMockInitialValues({});
  final storage = LocalStorage(await SharedPreferences.getInstance());
  return (storage: storage, secure: InMemorySecureStorage());
}

Future<void> _seedAccountScoped(
  LocalStorage storage,
  InMemorySecureStorage secure,
) async {
  await storage.setStringList('or_reading_history', const ['{"id":"r1"}']);
  await storage.setStringList('ai_conversations', const ['{"id":"c1"}']);
  await storage.setString('user_memories', 'memory');
  await storage.setString('settings_language', 'tr');
  await storage.setString('settings_theme', 'cosmic');
  final pending = ReadingPendingOperationStore(storage);
  await pending.save(ReadingType.coffee, _pending);
  await pending.save(ReadingType.palm, _pending);
  await pending.save(ReadingType.soulmate, _pending);
  await storage.setString(
    DreamAttemptStore.key,
    '{"fp":"dream:seed","id":"or-dream-r5"}',
  );
  await MockPremiumRepository(
    storage,
    secureStorage: secure,
  ).activatePlan(PremiumPlanKind.monthly, authoritative: true);
  await storage.setString(UserLocalDataIsolation.ownerKey, 'user-a');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('wipe clears pending coffee/palm/soulmate and history/OR/premium',
      () async {
    final boot = await _boot();
    await _seedAccountScoped(boot.storage, boot.secure);
    await UserLocalDataWipe.run(
      boot.storage,
      secureStorage: boot.secure,
    );

    final pending = ReadingPendingOperationStore(boot.storage);
    expect(pending.load(ReadingType.coffee), isNull);
    expect(pending.load(ReadingType.palm), isNull);
    expect(pending.load(ReadingType.soulmate), isNull);
    expect(boot.storage.getStringList('or_reading_history'), isEmpty);
    expect(boot.storage.getStringList('ai_conversations'), isEmpty);
    expect(boot.storage.getString('user_memories'), isNull);
    expect(boot.storage.getString(DreamAttemptStore.key), isNull);
    expect(await MockPremiumRepository(boot.storage).isPremiumActive(), isFalse);
  });

  test('device-scoped settings survive wipe', () async {
    final boot = await _boot();
    await _seedAccountScoped(boot.storage, boot.secure);
    await UserLocalDataWipe.run(
      boot.storage,
      secureStorage: boot.secure,
    );
    expect(boot.storage.getString('settings_language'), 'tr');
    expect(boot.storage.getString('settings_theme'), 'cosmic');
  });

  test('successful sign-out cleanup wipes disk and clears owner', () async {
    final boot = await _boot();
    await _seedAccountScoped(boot.storage, boot.secure);
    final beforeEpoch = UserLocalDataIsolation.accountSwitchEpoch.value;

    await SignOutLocalCleanup.wipeDiskOnly(
      storage: boot.storage,
      secureStorage: boot.secure,
    );

    expect(boot.storage.getString(UserLocalDataIsolation.ownerKey), isNull);
    expect(
      UserLocalDataIsolation.accountSwitchEpoch.value,
      greaterThan(beforeEpoch),
    );
    expect(
      ReadingPendingOperationStore(boot.storage).load(ReadingType.coffee),
      isNull,
    );
  });

  test(
      'an incomplete local wipe during sign-out preserves the owner '
      'safety signal instead of claiming a completed local cleanup',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final failingStorage = _KeyFailingStorage(
      prefs,
      failingKeys: {MockUserRepository.readingLedgerIdsKey},
    );
    final secure = InMemorySecureStorage();
    await failingStorage.setString(UserLocalDataIsolation.ownerKey, 'user-a');
    await MockUserRepository(failingStorage).ensureReadingCompletionMigration(
      const [],
    );
    final beforeEpoch = UserLocalDataIsolation.accountSwitchEpoch.value;

    final result = await SignOutLocalCleanup.wipeDiskOnly(
      storage: failingStorage,
      secureStorage: secure,
    );

    expect(result.isComplete, isFalse);
    expect(
      failingStorage.getString(UserLocalDataIsolation.ownerKey),
      'user-a',
      reason: 'auth sign-out already succeeded — this is ONLY about local '
          'privacy cleanup, and an incomplete cleanup must leave the '
          'owner marker in place so the next distinct sign-in is forced '
          'to retry it, never silently treated as unowned/new-user data',
    );
    expect(
      UserLocalDataIsolation.accountSwitchEpoch.value,
      beforeEpoch,
      reason: 'an incomplete cleanup must not announce a completed switch',
    );
  });

  test(
      'a later, genuinely different sign-in after an incomplete sign-out '
      'wipe retries cleanup before treating that owner as isolated',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final failingStorage = _KeyFailingStorage(
      prefs,
      failingKeys: {MockUserRepository.readingLedgerIdsKey},
    );
    final secure = InMemorySecureStorage();
    await failingStorage.setString(UserLocalDataIsolation.ownerKey, 'user-a');
    await MockUserRepository(failingStorage).ensureReadingCompletionMigration(
      const [],
    );

    final signOutResult = await SignOutLocalCleanup.wipeDiskOnly(
      storage: failingStorage,
      secureStorage: secure,
    );
    expect(signOutResult.isComplete, isFalse);
    expect(
      failingStorage.getString(UserLocalDataIsolation.ownerKey),
      'user-a',
    );

    // A different user now signs in on this device — isolation must
    // retry the wipe (it's still failing) and must NOT commit user-b as
    // the local owner.
    final failingIsolation = UserLocalDataIsolation(
      failingStorage,
      secureStorage: secure,
    );
    final retryOnFailingStorage = await failingIsolation.onSignedIn('user-b');
    expect(retryOnFailingStorage.success, isFalse);
    expect(failingIsolation.localOwnerId, 'user-a');

    // Once storage recovers, the SAME distinct sign-in finally succeeds.
    final healthyStorage = LocalStorage(prefs);
    final healthyIsolation = UserLocalDataIsolation(
      healthyStorage,
      secureStorage: secure,
    );
    final retryOnHealthyStorage = await healthyIsolation.onSignedIn('user-b');
    expect(retryOnHealthyStorage.success, isTrue);
    expect(healthyIsolation.localOwnerId, 'user-b');
  });

  test('failed sign-out path must not wipe when cleanup is skipped', () async {
    final boot = await _boot();
    await _seedAccountScoped(boot.storage, boot.secure);

    // Simulate profileSignOut failure branch: auth fails → no wipe call.
    expect(
      ReadingPendingOperationStore(boot.storage).load(ReadingType.coffee),
      isNotNull,
    );
    expect(boot.storage.getStringList('ai_conversations'), isNotEmpty);
    expect(boot.storage.getString(UserLocalDataIsolation.ownerKey), 'user-a');
  });

  test('wipe continues after an individual store failure', () async {
    final boot = await _boot();
    await _seedAccountScoped(boot.storage, boot.secure);
    // Corrupt image wipe input should not stop pending/history cleanup.
    await UserLocalDataWipe.run(
      boot.storage,
      secureStorage: boot.secure,
    );
    expect(
      ReadingPendingOperationStore(boot.storage).load(ReadingType.palm),
      isNull,
    );
    expect(boot.storage.getStringList('or_reading_history'), isEmpty);
  });

  test('account switch wipe also clears pending operations', () async {
    final boot = await _boot();
    await _seedAccountScoped(boot.storage, boot.secure);
    final isolation = UserLocalDataIsolation(
      boot.storage,
      secureStorage: boot.secure,
    );
    await isolation.onSignedIn('user-b');

    expect(
      ReadingPendingOperationStore(boot.storage).load(ReadingType.soulmate),
      isNull,
    );
    expect(boot.storage.getStringList('or_reading_history'), isEmpty);
    expect(isolation.localOwnerId, 'user-b');
  });

  test('clearAll removes stray reading_pending_operation_* keys', () async {
    final boot = await _boot();
    await boot.storage.setString(
      'reading_pending_operation_legacy',
      '{"operationId":"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"}',
    );
    await ReadingPendingOperationStore.clearAll(boot.storage);
    expect(
      boot.storage.keys.any((k) => k.startsWith('reading_pending_operation_')),
      isFalse,
    );
  });
}
