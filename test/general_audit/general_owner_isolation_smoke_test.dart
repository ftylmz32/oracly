/// G0 — owner switch A → B baseline: nothing account-scoped survives the
/// wipe; device settings do.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_wipe.dart';
import 'package:oracly_new/core/auth/user_local_data_wipe_keys.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/review_access_repository.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/dream/services/dream_attempt_store.dart';
import 'package:oracly_new/features/favorite_moments/data/local_favorite_moments_repository.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/gems/data/paid_ai_operation_store.dart';
import 'package:oracly_new/features/premium/data/soul_mate_result_store.dart';
import 'package:oracly_new/features/share_reopen/services/share_ownership_store.dart';
import 'package:oracly_new/features/star_map/artifacts/local_yildizname_artifact_repository.dart';
import 'package:oracly_new/features/tarot/data/datasources/tarot_local_datasource.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _ownerAStrings = <String, String>{
  LocalFavoriteMomentsRepository.key: '[{"id":"fav-a"}]',
  MockPremiumRepository.activeKey: 'true',
  MockPremiumRepository.purchaseTokenKey: 'synthetic-token-a',
  ReviewAccessRepository.grantedKey: 'true',
  GemWalletStore.serverBalanceCacheKey: '75',
  GemWalletStore.serverBalanceOwnerKey: 'owner-a-synthetic',
  PaidAiOperationStore.key: '[{"id":"op-a"}]',
  DreamAttemptStore.key: '{"attempt":"a"}',
  SoulMateResultStore.metaKey: '{"id":"sm-a"}',
  ShareOwnershipStore.key: '{"ref":"a"}',
  LocalYildiznameArtifactRepository.storageKey: '[{"id":"yn-a"}]',
  TarotLocalDataSource.activeKey: '{"reading":"a"}',
};

final _ownerALists = <String, List<String>>{
  'dream_records': ['{"id":"dream-a"}'],
  TarotLocalDataSource.historyKey: ['{"id":"tarot-a"}'],
  'coffee_readings': const [],
  'palm_readings': const [],
};

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

void main() {
  test('account wipe clears every account-scoped store, keeps settings',
      () async {
    final root = await Directory.systemTemp.createTemp('oracly-g0-owner-');
    addTearDown(() => root.delete(recursive: true));
    PathProviderPlatform.instance = _TempPathProvider(root.path);
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    for (final e in _ownerAStrings.entries) {
      await storage.setString(e.key, e.value);
    }
    for (final e in _ownerALists.entries) {
      await storage.setStringList(e.key, e.value);
    }
    await storage.setString('settings_language', 'tr');

    final result = await UserLocalDataWipe.run(
      storage,
      secureStorage: InMemorySecureStorage(),
    );

    expect(result.isComplete, isTrue, reason: '${result.failedOperations}');
    for (final key in _ownerAStrings.keys) {
      expect(storage.getString(key), isNull, reason: key);
    }
    for (final key in _ownerALists.keys) {
      expect(storage.getStringList(key) ?? const [], isEmpty, reason: key);
    }
    for (final key in UserLocalDataWipeKeys.gems) {
      expect(storage.keys.contains(key), isFalse, reason: key);
    }
    expect(storage.getString('settings_language'), 'tr');
  });
}
