/// Clear Discovery History must purge Coffee/Palm/Dream connected memory.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_dream_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_history_repository.dart';
import 'package:oracly_new/core/intelligence/data/personal_memory_store.dart';
import 'package:oracly_new/core/intelligence/services/personal_memory_service.dart';
import 'package:oracly_new/core/memory/oracly_memory.dart';
import 'package:oracly_new/core/memory/oracly_memory_store.dart';
import 'package:oracly_new/core/services/history_service.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/favorite_moments/data/local_favorite_moments_repository.dart';
import 'package:oracly_new/features/favorite_moments/models/favorite_moment.dart';
import 'package:oracly_new/features/favorite_moments/services/favorite_moments_service.dart';
import 'package:oracly_new/features/palm/data/palm_reading_store.dart';
import 'package:oracly_new/features/privacy/services/privacy_control_service.dart';
import 'package:oracly_new/features/tarot/data/datasources/tarot_local_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../personal_discovery/pde_test_fixtures.dart';
import '../birth_chart/evidence/test_birth_owner.dart';

const _keepToken = 'KEEP_SOULMATE_MEMORY_TOKEN_ZZ';

void main() {
  late SharedPreferences prefs;
  late LocalStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    storage = LocalStorage(prefs);
  });

  PrivacyControlService service() {
    return PrivacyControlService(
      history: HistoryService(MockHistoryRepository(storage)),
      favorites: FavoriteMomentsService(
        LocalFavoriteMomentsRepository(storage),
      ),
      personalMemory: PersonalMemoryService(PersonalMemoryStore(storage)),
      birthCharts: testBirthChartRepo(storage),
      storage: storage,
    );
  }

  bool hasSource(OraclyMemoryStore memory, String sourceId) =>
      memory.all().any((m) => m.source.id == sourceId);

  test('coffee palm dream clear removes source + connected memory', () async {
    final memory = OraclyMemoryStore(storage);
    final coffee = CoffeeReadingStore(storage, memory: memory);
    final palm = PalmReadingStore(storage, memory: memory);
    final dreams = LocalDreamRepository(storage, memory: memory);

    await coffee.save(pdeCoffee('c-ghost', 'Fincanda karar izi'));
    await palm.save(pdePalm('p-ghost', 'Avuçta iletişim izi'));
    await dreams.save(pdeDream('d-ghost', 'Rüyada belirsizlik'));

    expect(coffee.byId('c-ghost'), isNotNull);
    expect(palm.byId('p-ghost'), isNotNull);
    expect(await dreams.getById('d-ghost'), isNotNull);
    expect(hasSource(memory, 'c-ghost'), isTrue);
    expect(hasSource(memory, 'p-ghost'), isTrue);
    expect(hasSource(memory, 'd-ghost'), isTrue);

    await service().clearDiscoveryHistory();

    expect(CoffeeReadingStore(storage).all(), isEmpty);
    expect(PalmReadingStore(storage).all(), isEmpty);
    expect(await LocalDreamRepository(storage).getAll(), isEmpty);
    expect(hasSource(OraclyMemoryStore(storage), 'c-ghost'), isFalse);
    expect(hasSource(OraclyMemoryStore(storage), 'p-ghost'), isFalse);
    expect(hasSource(OraclyMemoryStore(storage), 'd-ghost'), isFalse);
  });

  test('restart after clear — no coffee/palm/dream ghost memory', () async {
    final memory = OraclyMemoryStore(storage);
    await CoffeeReadingStore(
      storage,
      memory: memory,
    ).save(pdeCoffee('c-restart', 'Karar yeniden'));
    await PalmReadingStore(
      storage,
      memory: memory,
    ).save(pdePalm('p-restart', 'İlişki yeniden'));
    await LocalDreamRepository(
      storage,
      memory: memory,
    ).save(pdeDream('d-restart', 'Değişim rüyası'));

    await service().clearDiscoveryHistory();

    final restarted = LocalStorage(prefs);
    final restartedMemory = OraclyMemoryStore(restarted);
    expect(CoffeeReadingStore(restarted).all(), isEmpty);
    expect(PalmReadingStore(restarted).all(), isEmpty);
    expect(await LocalDreamRepository(restarted).getAll(), isEmpty);
    expect(hasSource(restartedMemory, 'c-restart'), isFalse);
    expect(hasSource(restartedMemory, 'p-restart'), isFalse);
    expect(hasSource(restartedMemory, 'd-restart'), isFalse);
  });

  test('clear discovery does not wipe unrelated connected memory', () async {
    final memory = OraclyMemoryStore(storage);
    await CoffeeReadingStore(
      storage,
      memory: memory,
    ).save(pdeCoffee('c-only', 'Sadece kahve'));
    await memory.upsert(
      OraclyMemory(
        id: 'reading:soulmate:keep-1',
        kind: OraclyMemoryKind.reading,
        source: OraclyMemorySource(
          id: 'soulmate-keep-1',
          type: OraclyReadingType.soulmate,
          occurredAt: DateTime(2026, 3, 1),
          resultRef: 'soulmate-keep-1',
        ),
        summary: _keepToken,
      ),
    );

    await service().clearDiscoveryHistory();

    final after = OraclyMemoryStore(storage);
    expect(hasSource(after, 'c-only'), isFalse);
    expect(hasSource(after, 'soulmate-keep-1'), isTrue);
    expect(
      after.all().singleWhere((m) => m.source.id == 'soulmate-keep-1').summary,
      _keepToken,
    );
  });

  test('favorites remain; tarot/active clear; malformed rows empty', () async {
    final fav = LocalFavoriteMomentsRepository(storage);
    await fav.save(
      FavoriteMoment(
        id: 'fav-keep',
        source: FavoriteMomentSource.tarot,
        sourceRef: 'r-x',
        savedAt: DateTime(2026, 1, 1),
        occurredAt: DateTime(2026, 1, 1),
        quote: 'Keep me',
      ),
    );
    await storage.setStringList('or_reading_history', const ['r1']);
    await storage.setStringList(TarotLocalDataSource.historyKey, const ['t1']);
    await storage.setString(TarotLocalDataSource.activeKey, 'active');
    await storage.setStringList(CoffeeReadingStore.key, const ['{bad']);
    await storage.setStringList(PalmReadingStore.key, const ['not-json']);
    await storage.setStringList('dream_records', const ['d1']);

    final memory = OraclyMemoryStore(storage);
    await CoffeeReadingStore(
      storage,
      memory: memory,
    ).save(pdeCoffee('c-ok', 'İyi fincan'));

    await service().clearDiscoveryHistory();

    expect((await fav.getAll()).length, 1);
    expect(storage.getStringList('or_reading_history'), isEmpty);
    expect(storage.getStringList(TarotLocalDataSource.historyKey), isEmpty);
    expect(storage.getString(TarotLocalDataSource.activeKey), isNull);
    expect(storage.getStringList(CoffeeReadingStore.key), isEmpty);
    expect(storage.getStringList(PalmReadingStore.key), isEmpty);
    expect(storage.getStringList('dream_records'), isEmpty);
    expect(hasSource(OraclyMemoryStore(storage), 'c-ok'), isFalse);
  });

  test(
    'orphan type purge clears tarot/coffee/palm/dream/birthChart memory',
    () async {
      final memory = OraclyMemoryStore(storage);
      // Malformed sources + pre-existing connected memory ghosts.
      await storage.setStringList(CoffeeReadingStore.key, const ['{bad']);
      await storage.setStringList(PalmReadingStore.key, const ['not-json']);
      await storage.setStringList('dream_records', const ['{bad']);
      await storage.setStringList(TarotLocalDataSource.historyKey, const [
        '{bad',
      ]);

      Future<void> seed(OraclyReadingType type, String id) => memory.upsert(
        OraclyMemory(
          id: 'reading:${type.name}:$id',
          kind: OraclyMemoryKind.reading,
          source: OraclyMemorySource(
            id: id,
            type: type,
            occurredAt: DateTime(2026, 3, 1),
          ),
          summary: 'ghost',
        ),
      );

      await seed(OraclyReadingType.tarot, 't-orphan');
      await seed(OraclyReadingType.coffee, 'c-orphan');
      await seed(OraclyReadingType.palm, 'p-orphan');
      await seed(OraclyReadingType.dream, 'd-orphan');
      await seed(OraclyReadingType.birthChart, 'bc-orphan');
      await seed(OraclyReadingType.soulmate, 'soulmate-keep-2');

      await service().clearDiscoveryHistory();

      final after = OraclyMemoryStore(storage);
      expect(hasSource(after, 't-orphan'), isFalse);
      expect(hasSource(after, 'c-orphan'), isFalse);
      expect(hasSource(after, 'p-orphan'), isFalse);
      expect(hasSource(after, 'd-orphan'), isFalse);
      expect(hasSource(after, 'bc-orphan'), isFalse);
      expect(hasSource(after, 'soulmate-keep-2'), isTrue);
      expect(storage.getStringList(CoffeeReadingStore.key), isEmpty);
      expect(storage.getStringList(PalmReadingStore.key), isEmpty);
      expect(storage.getStringList('dream_records'), isEmpty);
      expect(storage.getStringList(TarotLocalDataSource.historyKey), isEmpty);

      final restarted = OraclyMemoryStore(LocalStorage(prefs));
      expect(hasSource(restarted, 't-orphan'), isFalse);
      expect(hasSource(restarted, 'soulmate-keep-2'), isTrue);
    },
  );

  test('Discovery clear same raw id — SoulMate survives Coffee wipe', () async {
    final memory = OraclyMemoryStore(storage);
    await CoffeeReadingStore(
      storage,
      memory: memory,
    ).save(pdeCoffee('shared_id', 'Kahve'));
    await memory.upsert(
      OraclyMemory(
        id: 'reading:soulmate:shared_id',
        kind: OraclyMemoryKind.reading,
        source: OraclyMemorySource(
          id: 'shared_id',
          type: OraclyReadingType.soulmate,
          occurredAt: DateTime(2026, 3, 1),
        ),
        summary: _keepToken,
      ),
    );
    // Authoritative SoulMate meta with same raw id as Coffee.
    await storage.setString(
      'soulmate_latest',
      '{"id":"shared_id","createdAt":"2026-03-01T00:00:00.000Z",'
          '"name":"N","birthDate":"2000-01-01T00:00:00.000Z",'
          '"portraitPath":"/tmp/p.jpg","localeCode":"tr",'
          '"parts":{"energy":"e","attraction":"a","dynamics":"d",'
          '"feeling":"f","yourSide":"y","meeting":"","authoritative":true}}',
    );

    await service().clearDiscoveryHistory();

    expect(CoffeeReadingStore(storage).all(), isEmpty);
    expect(hasSource(OraclyMemoryStore(storage), 'shared_id'), isTrue);
    final after = OraclyMemoryStore(storage).all();
    expect(
      after
          .singleWhere((m) => m.source.type == OraclyReadingType.soulmate)
          .summary,
      _keepToken,
    );
    expect(
      after.any((m) => m.source.type == OraclyReadingType.coffee),
      isFalse,
    );
    expect(storage.getString('soulmate_latest'), isNotNull);
  });
}
