/// Phase 10 — cross-feature storage key isolation + cold restart.
/// REAL PROVIDER CALLS = 0. Production unmodified.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/palm/data/palm_reading_store.dart';
import 'package:oracly_new/features/reading_operation/models/reading_operation_status.dart';
import 'package:oracly_new/features/tarot/data/datasources/tarot_local_datasource.dart';
import 'package:oracly_new/features/tarot/data/repositories/tarot_reading_repository_impl.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const coffeePending = 'reading_pending_operation_coffee';
  const palmPending = 'reading_pending_operation_palm';

  test('feature storage keys are pairwise distinct', () {
    final keys = <String, String>{
      'tarot.active': TarotLocalDataSource.activeKey,
      'tarot.history': TarotLocalDataSource.historyKey,
      'coffee.history': CoffeeReadingStore.key,
      'palm.history': PalmReadingStore.key,
      'coffee.pending': coffeePending,
      'palm.pending': palmPending,
      'premium.active': MockPremiumRepository.activeKey,
      'premium.plan': MockPremiumRepository.planKey,
    };
    final seen = <String>{};
    for (final e in keys.entries) {
      expect(
        seen.add(e.value),
        isTrue,
        reason: 'collision on ${e.value} for ${e.key}',
      );
    }
    expect(coffeePending, contains(ReadingType.coffee.name));
    expect(palmPending, contains(ReadingType.palm.name));
  });

  test('shared LocalStorage journey keeps feature blobs isolated', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());

    final tarot = TarotReadingRepositoryImpl.fromStorage(storage);
    final session = ReadingSession(
      id: 'p10_tarot_active',
      deckId: 'classic',
      shuffleSeed: 42,
      spread: TarotSpreadType.threeCard,
      intention: const TarotIntention(text: 'phase10'),
      startedAt: DateTime.utc(2026, 9, 25),
    );
    await tarot.saveSession(session);

    await storage.setString(CoffeeReadingStore.key, '[{"id":"c1"}]');
    await storage.setString(PalmReadingStore.key, '[{"id":"p1"}]');
    await storage.setString('dream_records', '[{"id":"d1"}]');
    await storage.setBool(MockPremiumRepository.activeKey, true);
    await storage.setInt(MockPremiumRepository.planKey, 1);
    await storage.setString('astrology_history', '[{"id":"a1"}]');
    await storage.setString('birth_chart_latest', '{"ok":true}');
    await storage.setString(
      coffeePending,
      '{"operationId":"op_c","sourceRequestId":"sr_c","mimeType":"image/jpeg"}',
    );

    expect(storage.getString(CoffeeReadingStore.key), contains('c1'));
    expect(storage.getString(PalmReadingStore.key), contains('p1'));
    expect(storage.getString('dream_records'), contains('d1'));
    expect(storage.getBool(MockPremiumRepository.activeKey), isTrue);
    expect(storage.getString('astrology_history'), contains('a1'));
    expect(storage.getString('birth_chart_latest'), contains('ok'));
    expect(storage.getString(coffeePending), contains('op_c'));

    final active = await tarot.loadActiveSession();
    expect(active?.id, 'p10_tarot_active');
    expect(active?.spread, TarotSpreadType.threeCard);

    final storage2 = LocalStorage(await SharedPreferences.getInstance());
    final tarot2 = TarotReadingRepositoryImpl.fromStorage(storage2);
    expect((await tarot2.loadActiveSession())?.id, 'p10_tarot_active');
    expect(storage2.getString(CoffeeReadingStore.key), contains('c1'));
    expect(storage2.getString(PalmReadingStore.key), contains('p1'));
    expect(storage2.getBool(MockPremiumRepository.activeKey), isTrue);
    expect(storage2.getString(coffeePending), contains('op_c'));

    await tarot2.clearActiveSession();
    expect(await tarot2.loadActiveSession(), isNull);
    expect(storage2.getString(CoffeeReadingStore.key), contains('c1'));
    expect(storage2.getString(PalmReadingStore.key), contains('p1'));
    expect(storage2.getString('dream_records'), contains('d1'));
    expect(storage2.getString(coffeePending), contains('op_c'));
  });

  test('coffee/palm pending ops do not share Tarot active key', () {
    expect(coffeePending, isNot(TarotLocalDataSource.activeKey));
    expect(palmPending, isNot(TarotLocalDataSource.activeKey));
    expect(coffeePending, isNot(palmPending));
  });
}
