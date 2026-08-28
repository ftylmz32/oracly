/// Privacy Control Center tests — real actions, no ghost data.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_birth_chart_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_history_repository.dart';
import 'package:oracly_new/core/intelligence/data/personal_memory_store.dart';
import 'package:oracly_new/core/services/history_service.dart';
import 'package:oracly_new/features/favorite_moments/data/local_favorite_moments_repository.dart';
import 'package:oracly_new/features/favorite_moments/models/favorite_moment.dart';
import 'package:oracly_new/features/favorite_moments/services/favorite_moments_service.dart';
import 'package:oracly_new/core/intelligence/services/personal_memory_service.dart';
import 'package:oracly_new/features/privacy/services/privacy_control_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LocalStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await LocalStorage.open();
  });

  PrivacyControlService service(PersonalMemoryService personalMemory) {
    return PrivacyControlService(
      history: HistoryService(MockHistoryRepository(storage)),
      favorites: FavoriteMomentsService(LocalFavoriteMomentsRepository(storage)),
      personalMemory: personalMemory,
      birthCharts: LocalBirthChartRepository(storage),
      storage: storage,
    );
  }

  test('clear favorites removes stored moments', () async {
    final repo = LocalFavoriteMomentsRepository(storage);
    await repo.save(
      FavoriteMoment(
        id: 'm1',
        source: FavoriteMomentSource.tarot,
        sourceRef: 'r1',
        savedAt: DateTime(2026, 1, 1),
        occurredAt: DateTime(2026, 1, 1),
        quote: 'Test',
      ),
    );
    expect((await repo.getAll()).length, 1);

    await service(PersonalMemoryService(PersonalMemoryStore(storage))).clearFavorites();
    expect(await repo.getAll(), isEmpty);
  });

  test('reset memory clears personal and legacy memory keys', () async {
    final personalMemory = PersonalMemoryService(PersonalMemoryStore(storage));
    await storage.setString(
      PersonalMemoryStore.key,
      '{"schemaVersion":1,"preferredName":"Ada","themes":[],"recentDiscoveries":[],"preferences":[],"recentTopics":[],"fingerprint":"x"}',
    );
    await storage.setStringList('user_memories', const ['note']);
    await storage.setStringList('discovery_surface_memory_v1', const ['x']);

    await service(personalMemory).resetMemorySummary();

    expect(storage.getString(PersonalMemoryStore.key), isNull);
    expect(storage.getStringList('user_memories'), isNull);
    expect(storage.getStringList('discovery_surface_memory_v1'), isNull);
  });

  test('clear discovery history empties journal sources', () async {
    await storage.setStringList('or_reading_history', const ['r1']);
    await storage.setStringList('dream_records', const ['d1']);
    await storage.setStringList('coffee_readings', const ['c1']);
    await storage.setStringList('palm_readings', const ['p1']);
    await storage.setStringList('astrology_history', const ['a1']);
    await storage.setStringList('ai_conversations', const ['or1']);

    await service(PersonalMemoryService(PersonalMemoryStore(storage)))
        .clearDiscoveryHistory();

    expect(storage.getStringList('or_reading_history'), isEmpty);
    expect(storage.getStringList('dream_records'), isEmpty);
    expect(storage.getStringList('coffee_readings'), isEmpty);
    expect(storage.getStringList('palm_readings'), isEmpty);
    expect(storage.getStringList('astrology_history'), isEmpty);
    expect(storage.getStringList('ai_conversations'), isEmpty);
  });
}
