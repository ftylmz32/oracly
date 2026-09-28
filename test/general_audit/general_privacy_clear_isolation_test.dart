/// G0 — privacy clears touch only their own stores.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_history_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/review_access_repository.dart';
import 'package:oracly_new/core/intelligence/data/personal_memory_store.dart';
import 'package:oracly_new/core/intelligence/services/personal_memory_service.dart';
import 'package:oracly_new/core/memory/oracly_memory_store.dart';
import 'package:oracly_new/core/services/history_service.dart';
import 'package:oracly_new/features/favorite_moments/data/local_favorite_moments_repository.dart';
import 'package:oracly_new/features/favorite_moments/services/favorite_moments_service.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/premium/data/soul_mate_result_store.dart';
import 'package:oracly_new/features/privacy/services/privacy_control_service.dart';
import 'package:oracly_new/features/privacy/services/privacy_dream_clear.dart';
import 'package:oracly_new/features/tarot/data/datasources/tarot_local_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/birth_chart/evidence/test_birth_owner.dart';

const _readings = {
  'dream_records': 'd1',
  'coffee_readings': 'c1',
  'palm_readings': 'p1',
  'astrology_history': 'a1',
};

final _accountScoped = <String, String>{
  SoulMateResultStore.metaKey: '{"id":"sm1"}',
  MockPremiumRepository.activeKey: 'true',
  ReviewAccessRepository.grantedKey: 'true',
  GemWalletStore.balanceKey: '50',
};

Future<LocalStorage> _seed() async {
  SharedPreferences.setMockInitialValues({});
  final storage = await LocalStorage.open();
  for (final e in _readings.entries) {
    await storage.setStringList(e.key, [e.value]);
  }
  await storage.setStringList(TarotLocalDataSource.historyKey, const ['t1']);
  for (final e in _accountScoped.entries) {
    await storage.setString(e.key, e.value);
  }
  return storage;
}

PrivacyControlService _service(LocalStorage storage) => PrivacyControlService(
      history: HistoryService(MockHistoryRepository(storage)),
      favorites: FavoriteMomentsService(LocalFavoriteMomentsRepository(storage)),
      personalMemory: PersonalMemoryService(PersonalMemoryStore(storage)),
      birthCharts: testBirthChartRepo(storage),
      storage: storage,
    );

void _expectAccountScopedKept(LocalStorage storage) {
  for (final e in _accountScoped.entries) {
    expect(storage.getString(e.key), e.value, reason: e.key);
  }
}

void main() {
  test('Dream clear leaves Tarot / Coffee / Palm / Astrology untouched',
      () async {
    final storage = await _seed();
    expect(await PrivacyDreamClear.run(storage, OraclyMemoryStore(storage)),
        isTrue);
    expect(storage.getStringList('dream_records') ?? const [], isEmpty);
    for (final key in ['coffee_readings', 'palm_readings', 'astrology_history']) {
      expect(storage.getStringList(key), [_readings[key]], reason: key);
    }
    expect(storage.getStringList(TarotLocalDataSource.historyKey), ['t1']);
    _expectAccountScopedKept(storage);
  });

  test('favorites clear and memory reset never delete readings', () async {
    final storage = await _seed();
    await _service(storage).clearFavorites();
    await _service(storage).resetMemorySummary();
    for (final e in _readings.entries) {
      expect(storage.getStringList(e.key), [e.value], reason: e.key);
    }
    expect(storage.getStringList(TarotLocalDataSource.historyKey), ['t1']);
    _expectAccountScopedKept(storage);
  });

  test('discovery clear keeps SoulMate, Premium, review access and gems',
      () async {
    final storage = await _seed();
    await _service(storage).clearDiscoveryHistory();
    for (final key in _readings.keys) {
      expect(storage.getStringList(key) ?? const [], isEmpty, reason: key);
    }
    _expectAccountScopedKept(storage);
  });
}
