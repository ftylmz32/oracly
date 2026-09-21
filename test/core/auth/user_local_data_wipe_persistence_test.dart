/// P0-1 / 1A + 1B — UserLocalDataWipe must treat a `false` (non-throwing)
/// LocalStorage result exactly like a thrown exception: the key/operation
/// is recorded in failedOperations, and every OTHER step still runs
/// (best-effort per item, never per group).
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_wipe.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/core/storage/premium_credential_keys.dart';
import 'package:oracly_new/features/premium/services/soul_mate_generation_session.dart';
import 'package:oracly_new/screens/profile/data/profile_photo_store.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/false_return_local_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FalseReturnLocalStorage storage;
  late InMemorySecureStorage secure;
  late Directory root;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = FalseReturnLocalStorage(await SharedPreferences.getInstance());
    secure = InMemorySecureStorage();
    root = await Directory.systemTemp.createTemp('oracly-wipe-persistence-');
    PathProviderPlatform.instance = _TempPathProvider(root.path);
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test(
      'a single false-returning setStringList is recorded as a failure, and '
      'every other step still runs to completion', () async {
    storage.falseReturnKeys.add('or_reading_history');
    await storage.setString('user_name', 'stale-name');

    final result = await UserLocalDataWipe.run(storage, secureStorage: secure);

    expect(result.isComplete, isFalse);
    expect(result.failedOperations, contains('or_reading_history'));
    // A step positioned well after the failing one in run() still ran —
    // proving one false result never stops the rest of the sequence.
    expect(storage.getString('user_name'), isNull);
  });

  test(
      'a single false-returning remove is recorded as a failure without '
      'stopping later steps', () async {
    storage.falseReturnRemoveKeys.add('birth_chart_latest');
    await storage.setString('onboarding_setup_draft', 'draft');

    final result = await UserLocalDataWipe.run(storage, secureStorage: secure);

    expect(result.isComplete, isFalse);
    expect(result.failedOperations, contains('birth_chart_latest'));
    expect(storage.getString('onboarding_setup_draft'), isNull);
  });

  test(
      '_clearKeys: a false-returning key inside UserLocalDataWipeKeys.profile '
      'is recorded, and every OTHER key in the same group is still removed '
      '(per-key, not per-group)', () async {
    await storage.setStringList(
      MockUserRepository.readingLedgerIdsKey,
      const ['r1', 'r2'],
    );
    await storage.setString('profile_name', 'Old Owner');
    storage.falseReturnRemoveKeys.add(MockUserRepository.readingLedgerIdsKey);

    final result = await UserLocalDataWipe.run(storage, secureStorage: secure);

    expect(result.isComplete, isFalse);
    expect(result.failedOperations, contains(MockUserRepository.readingLedgerIdsKey));
    expect(
      storage.getStringList(MockUserRepository.readingLedgerIdsKey),
      isNotNull,
      reason: 'the false-returning key genuinely was not removed',
    );
    // A sibling key in the SAME group (profile) was still attempted and
    // succeeded.
    expect(storage.getString('profile_name'), isNull);
  });

  test(
      'MockPremiumRepository.clearPersistedLocalState: a false-returning key '
      'inside the composite premium cleanup surfaces as a wipe failure', () async {
    await storage.setBool(MockPremiumRepository.activeKey, true);
    storage.falseReturnRemoveKeys.add(MockPremiumRepository.activeKey);

    final result = await UserLocalDataWipe.run(storage, secureStorage: secure);

    expect(result.isComplete, isFalse);
    expect(result.failedOperations, contains('premium_local_state'));
    expect(
      storage.getBool(MockPremiumRepository.activeKey),
      isTrue,
      reason: 'the false-returning key genuinely was not removed',
    );
  });

  test(
      'ReadingPendingOperationStore.clearAll: a false-returning known '
      'ReadingType key surfaces as a wipe failure even though it was never '
      'set (clearAll always attempts every ReadingType key)', () async {
    storage.falseReturnRemoveKeys.add('reading_pending_operation_coffee');

    final result = await UserLocalDataWipe.run(storage, secureStorage: secure);

    expect(result.isComplete, isFalse);
    expect(result.failedOperations, contains('reading_pending_operations'));
  });

  test(
      'ReadingPendingOperationStore.clearAll: a false-returning STRAY '
      'pending-operation key is also caught and left in place for retry', () async {
    await storage.setString('reading_pending_operation_stray_x', '{"id":"x"}');
    storage.falseReturnRemoveKeys.add('reading_pending_operation_stray_x');

    final result = await UserLocalDataWipe.run(storage, secureStorage: secure);

    expect(result.isComplete, isFalse);
    expect(result.failedOperations, contains('reading_pending_operations'));
    expect(
      storage.getString('reading_pending_operation_stray_x'),
      isNotNull,
      reason: 'the false-returning key genuinely was not removed',
    );
  });

  test(
      'SoulMateGenerationSessionStore.clearStrict: a false-returning key '
      'surfaces as a wipe failure instead of being silently ignored', () async {
    await storage.setString(SoulMateGenerationSessionStore.key, '{}');
    storage.falseReturnRemoveKeys.add(SoulMateGenerationSessionStore.key);

    final result = await UserLocalDataWipe.run(storage, secureStorage: secure);

    expect(result.isComplete, isFalse);
    expect(result.failedOperations, contains('soul_mate_generation_session'));
  });

  test(
      'ProfilePhotoStore.clearStrict: a false-returning key-removal (file '
      'delete never even attempted, since there is no path) surfaces as a '
      'wipe failure', () async {
    await storage.setString(ProfilePhotoStore.key, '');
    storage.falseReturnRemoveKeys.add(ProfilePhotoStore.key);

    final result = await UserLocalDataWipe.run(storage, secureStorage: secure);

    expect(result.isComplete, isFalse);
    expect(result.failedOperations, contains('profile_photo'));
  });

  test(
      'MockPremiumRepository.clearPersistedLocalState: a THROWING middle '
      'Premium key still lets later Premium SharedPreferences keys and '
      'secure credential deletes run — wipe remains incomplete', () async {
    await storage.setBool(MockPremiumRepository.activeKey, true);
    await storage.setString(MockPremiumRepository.planKey, 'yearly');
    await storage.setString(
      MockPremiumRepository.legacyCredentialPrefKeys.first,
      'legacy-token',
    );
    await secure.write(PremiumCredentialKeys.purchaseToken, 'tok');
    await secure.write(PremiumCredentialKeys.transactionId, 'txn');
    storage.throwingRemoveKeys.add(MockPremiumRepository.activeKey);

    final result = await UserLocalDataWipe.run(storage, secureStorage: secure);

    expect(result.isComplete, isFalse);
    expect(result.failedOperations, contains('premium_local_state'));
    expect(
      storage.attempts[MockPremiumRepository.planKey] ?? 0,
      greaterThan(0),
      reason: 'later Premium key must still be attempted after a throw',
    );
    expect(
      storage.attempts[MockPremiumRepository.legacyCredentialPrefKeys.first] ??
          0,
      greaterThan(0),
    );
    expect(
      secure.snapshot.containsKey(PremiumCredentialKeys.purchaseToken),
      isFalse,
    );
    expect(
      secure.snapshot.containsKey(PremiumCredentialKeys.transactionId),
      isFalse,
    );
  });

  test(
      'ReadingPendingOperationStore.clearAll: a THROWING known key still '
      'attempts remaining known types and stray pending keys', () async {
    await storage.setString('reading_pending_operation_coffee', '{}');
    await storage.setString('reading_pending_operation_palm', '{}');
    await storage.setString('reading_pending_operation_stray_y', '{}');
    storage.throwingRemoveKeys.add('reading_pending_operation_coffee');

    final result = await UserLocalDataWipe.run(storage, secureStorage: secure);

    expect(result.isComplete, isFalse);
    expect(result.failedOperations, contains('reading_pending_operations'));
    expect(
      storage.getString('reading_pending_operation_palm'),
      isNull,
      reason: 'sibling known type still removed after coffee threw',
    );
    expect(
      storage.getString('reading_pending_operation_stray_y'),
      isNull,
      reason: 'stray pending key still attempted after a throw',
    );
    expect(
      storage.getString('reading_pending_operation_coffee'),
      isNotNull,
    );
  });

  test(
      'mixed false + throw across Premium keys: both recorded, cleanup '
      'continues for siblings', () async {
    final keys = MockPremiumRepository.localUserBoundKeys;
    expect(keys.length, greaterThanOrEqualTo(2));
    await storage.setBool(keys[0], true);
    await storage.setString(keys[1], 'x');
    if (keys.length > 2) {
      await storage.setString(keys[2], 'y');
    }
    storage.falseReturnRemoveKeys.add(keys[0]);
    storage.throwingRemoveKeys.add(keys[1]);

    final result = await UserLocalDataWipe.run(storage, secureStorage: secure);

    expect(result.isComplete, isFalse);
    expect(result.failedOperations, contains('premium_local_state'));
    if (keys.length > 2) {
      expect(storage.attempts[keys[2]] ?? 0, greaterThan(0));
    }
  });

  test('a fully healthy storage backend reports a complete wipe', () async {
    final result = await UserLocalDataWipe.run(storage, secureStorage: secure);
    expect(result.isComplete, isTrue);
    expect(result.failedOperations, isEmpty);
  });
}

class _TempPathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _TempPathProvider(this.root);
  final String root;

  @override
  Future<String?> getApplicationSupportPath() async => root;
  @override
  Future<String?> getApplicationDocumentsPath() async => root;
  @override
  Future<String?> getTemporaryPath() async => root;
  @override
  Future<String?> getApplicationCachePath() async => root;
}
