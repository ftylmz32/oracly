/// EPIC-011 — Daily ritual unit tests.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/universe/oracly_universe_state.dart';
import 'package:oracly_new/features/daily_ritual/services/daily_ritual_intent.dart';
import 'package:oracly_new/features/daily_ritual/services/daily_ritual_reflections.dart';
import 'package:oracly_new/features/daily_ritual/services/daily_ritual_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('DailyRitualReflections', () {
    test('reflection is deterministic for the same day', () {
      final state = OraclyUniverseState.current(DateTime(2026, 8, 6, 9));
      final a = DailyRitualReflections.reflection(state);
      final b = DailyRitualReflections.reflection(state);
      expect(a, b);
      expect(a.isNotEmpty, isTrue);
    });

    test('welcome varies by ritual time', () {
      final morning = OraclyUniverseState.current(DateTime(2026, 8, 6, 8));
      final night = OraclyUniverseState.current(DateTime(2026, 8, 6, 22));
      expect(
        DailyRitualReflections.welcome(morning),
        isNot(equals(DailyRitualReflections.welcome(night))),
      );
    });
  });

  group('DailyRitualService', () {
    late LocalStorage storage;
    late DailyRitualService service;
    final day = DateTime(2026, 8, 6);

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = LocalStorage(await SharedPreferences.getInstance());
      service = DailyRitualService(storage);
    });

    test('loads empty day by default', () {
      final state = service.loadToday(day);
      expect(state.reflectionRead, isFalse);
      expect(state.cardDrawn, isFalse);
      expect(state.personalThought, isNull);
      expect(state.hasEngaged, isFalse);
    });

    test('persists reflection, card, and thought independently', () async {
      await service.markReflectionRead(day);
      await service.markCardDrawn(day);
      await service.saveThought('Bugün sakin hissettim.', day);

      final state = service.loadToday(day);
      expect(state.reflectionRead, isTrue);
      expect(state.cardDrawn, isTrue);
      expect(state.personalThought, 'Bugün sakin hissettim.');
      expect(state.hasEngaged, isTrue);
    });
  });

  group('DailyRitualIntent', () {
    test('consume returns true once for pending draw', () {
      DailyRitualIntent.requestDailyCardDraw();
      expect(DailyRitualIntent.consumePendingDraw(), isTrue);
      expect(DailyRitualIntent.consumePendingDraw(), isFalse);
    });
  });
}
