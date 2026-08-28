/// ORACLY gözlem — real evidence, anti-repetition, no invention.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_sources.dart';
import 'package:oracly_new/features/personal_discovery/models/surfaced_theme_record.dart';
import 'package:oracly_new/features/personal_discovery/services/oracly_observation_service.dart';
import 'package:oracly_new/features/personal_discovery/services/personal_discovery_profile_builder.dart';

import 'pde_test_fixtures.dart';

void main() {
  final now = DateTime(2026, 8, 15);

  test('returns null without enough recurring evidence', () {
    final profile = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [pdeTarot('r1', 'Cesaretle bir adım at.')],
      ),
      now: now,
    );
    expect(
      OraclyObservationService.resolve(profile, recent: const [], surface: 'profile'),
      isNull,
    );
  });

  test('returns null when every theme was recently surfaced on that surface', () {
    final profile = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [
          pdeTarot('r1', 'Kariyer görünüyor.'),
          pdeTarot('r2', 'Kariyer yeniden beliriyor.'),
        ],
        coffee: [
          pdeCoffee('c1', 'Kariyer sabır ister.'),
          pdeCoffee('c2', 'Bu kariyer yolu yavaş.'),
        ],
      ),
      now: now,
    );
    final recent = [
      SurfacedThemeRecord(
        theme: 'kariyer',
        surface: 'profile',
        at: now.subtract(const Duration(hours: 3)),
      ),
    ];
    expect(
      OraclyObservationService.resolve(
        profile,
        recent: recent,
        surface: 'profile',
        now: now,
      ),
      isNull,
    );
  });

  test('surfaces a grounded recurring theme with observational copy', () {
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
    final observation = OraclyObservationService.resolve(
      profile,
      recent: const [],
      surface: 'journal',
      now: now,
    );
    expect(observation, isNotNull);
    expect(observation!.line.toLowerCase(), contains('karar'));
    expect(observation.line.toLowerCase(), isNot(contains('sen ')));
    expect(observation.line.toLowerCase(), isNot(contains('kişiliğin')));
  });

  test('prefers an alternative theme when the leading one is overused', () {
    final profile = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [
          pdeTarot('r1', 'Kariyer görünüyor.'),
          pdeTarot('r2', 'Değişim kapıda.'),
        ],
        coffee: [
          pdeCoffee('c1', 'Kariyer sabır ister.'),
          pdeCoffee('c2', 'Bu değişim yumuşak.'),
        ],
      ),
      now: now,
    );
    final recent = [
      SurfacedThemeRecord(
        theme: 'kariyer',
        surface: 'profile',
        at: now.subtract(const Duration(hours: 6)),
      ),
    ];
    final observation = OraclyObservationService.resolve(
      profile,
      recent: recent,
      surface: 'profile',
      now: now,
    );
    expect(observation?.theme, 'değişim');
  });
}
