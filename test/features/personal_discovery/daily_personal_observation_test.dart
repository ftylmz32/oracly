/// Daily personal observation — evidence, cache, anti-repetition.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oracly_new/features/personal_discovery/data/daily_personal_observation_store.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_sources.dart';
import 'package:oracly_new/features/personal_discovery/services/daily_personal_observation_service.dart';
import 'package:oracly_new/features/personal_discovery/services/personal_discovery_profile_builder.dart';

import 'pde_test_fixtures.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('returns null without recurring cross-modal evidence', () async {
    SharedPreferences.setMockInitialValues({});
    final store = DailyPersonalObservationStore(
      LocalStorage(await SharedPreferences.getInstance()),
    );
    final profile = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [pdeTarot('r1', 'Cesaretle bir adım at.')],
      ),
    );
    expect(
      DailyPersonalObservationService.resolve(
        profile,
        store: store,
        recent: const [],
        surface: 'profile',
      ),
      isNull,
    );
  });

  test('uses observational copy without identity labels', () async {
    SharedPreferences.setMockInitialValues({});
    final store = DailyPersonalObservationStore(
      LocalStorage(await SharedPreferences.getInstance()),
    );
    final now = DateTime(2026, 8, 15);
    final profile = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [
          pdeTarot('r1', 'Karar verme zamanı gelmiş.'),
          pdeTarot('r2', 'Bu karar yavaş ilerliyor.'),
        ],
        coffee: [
          pdeCoffee('c1', 'Karar verme sabır ister.'),
          pdeCoffee('c2', 'Karar konusu yeniden görünüyor.'),
        ],
      ),
      now: now,
    );
    final observation = DailyPersonalObservationService.resolve(
      profile,
      store: store,
      recent: const [],
      surface: 'profile',
      now: now,
    );
    expect(observation, isNotNull);
    expect(observation!.line, contains('keşfinde'));
    expect(observation.line.toLowerCase(), contains('karar'));
    expect(observation.line.toLowerCase(), isNot(contains('sen ')));
    expect(observation.line.toLowerCase(), isNot(contains('birisin')));
  });

  test('same evidence same day returns cached line', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final store = DailyPersonalObservationStore(storage);
    final now = DateTime(2026, 8, 15);
    final profile = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [
          pdeTarot('r1', 'Karar verme zamanı gelmiş.'),
          pdeTarot('r2', 'Bu karar yavaş ilerliyor.'),
        ],
        coffee: [
          pdeCoffee('c1', 'Karar verme sabır ister.'),
          pdeCoffee('c2', 'Karar konusu yeniden görünüyor.'),
        ],
      ),
      now: now,
    );
    final first = DailyPersonalObservationService.resolve(
      profile,
      store: store,
      recent: const [],
      surface: 'profile',
      now: now,
    );
    final second = DailyPersonalObservationService.resolve(
      profile,
      store: store,
      recent: const [],
      surface: 'journal',
      now: now.add(const Duration(hours: 2)),
    );
    expect(first?.line, second?.line);
  });

  test('same evidence new day avoids identical sentence', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final store = DailyPersonalObservationStore(storage);
    final profile = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [
          pdeTarot('r1', 'Karar verme zamanı gelmiş.'),
          pdeTarot('r2', 'Bu karar yavaş ilerliyor.'),
        ],
        coffee: [
          pdeCoffee('c1', 'Karar verme sabır ister.'),
          pdeCoffee('c2', 'Karar konusu yeniden görünüyor.'),
        ],
      ),
      now: DateTime(2026, 8, 15),
    );
    final dayOne = DailyPersonalObservationService.resolve(
      profile,
      store: store,
      recent: const [],
      surface: 'profile',
      now: DateTime(2026, 8, 15),
    );
    final dayTwo = DailyPersonalObservationService.resolve(
      profile,
      store: store,
      recent: const [],
      surface: 'profile',
      now: DateTime(2026, 8, 16),
    );
    expect(dayOne, isNotNull);
    expect(dayTwo, isNotNull);
    expect(dayOne!.line, isNot(equals(dayTwo!.line)));
  });
}
