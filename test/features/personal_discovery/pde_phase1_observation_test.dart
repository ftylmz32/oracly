/// Phase 1 — observations, cross insights, recency.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/models/birth_profile.dart';
import 'package:oracly_new/features/personal_discovery/models/discovery_theme_strength.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_sources.dart';
import 'package:oracly_new/features/personal_discovery/services/discovery_recency.dart';
import 'package:oracly_new/features/personal_discovery/services/personal_discovery_profile_builder.dart';

import 'pde_test_fixtures.dart';

void main() {
  final now = DateTime(2026, 8, 15);

  test('A empty user', () {
    final p = PersonalDiscoveryProfileBuilder.from(
      const PersonalDiscoverySources(),
      now: now,
    );
    expect(p.observations, isEmpty);
    expect(p.crossInsights, isEmpty);
    expect(p.hasHistory, isFalse);
  });

  test('B birth date only', () {
    final p = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        birth: BirthProfile(
          birthDate: DateTime(1990, 3, 21),
          birthPlace: 'İzmir',
        ),
      ),
      now: now,
    );
    expect(p.hasBirth, isTrue);
    expect(p.observations, isEmpty);
  });

  test('C one Tarot result is observed only', () {
    final p = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [pdeTarot('r1', 'Kariyer yolunda sakin ilerle.')],
      ),
      now: now,
    );
    expect(p.observations, isNotEmpty);
    expect(p.crossInsights.single.confidence, DiscoveryThemeStrength.observed);
    expect(p.recurringThemes, isEmpty);
  });

  test('D two sources sharing a theme', () {
    final p = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [pdeTarot('r1', 'Kariyer teması görünüyor.')],
        coffee: [pdeCoffee('c1', 'İş hayatında kariyer için sabır.')],
      ),
      now: now,
    );
    final insight = p.crossInsights.firstWhere((i) => i.theme == 'kariyer');
    expect(insight.isCrossModal, isTrue);
    expect(insight.confidence, DiscoveryThemeStrength.recurring);
    expect(insight.sourceCount, 2);
  });

  test('E three sources sharing a theme → strong', () {
    final p = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [pdeTarot('r1', 'Değişim kapıda.')],
        coffee: [pdeCoffee('c1', 'Bu değişim yumuşak.')],
        dreams: [pdeDream('d1', 'Rüyada değişim vardı.')],
      ),
      now: now,
    );
    final insight = p.crossInsights.firstWhere((i) => i.theme == 'değişim');
    expect(insight.confidence, DiscoveryThemeStrength.strong);
    expect(insight.sourceCount, 3);
  });

  test('F recent theme outweighs old theme of equal count', () {
    final old = DateTime(2025, 12, 1);
    final recent = DateTime(2026, 8, 14);
    final p = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [
          pdeTarot('old1', 'Cesaretle bir adım at.', at: old),
          pdeTarot('old2', 'Cesaret teması yeniden.', at: old),
        ],
        coffee: [
          pdeCoffee('new1', 'Kariyer sabır ister.', at: recent),
        ],
        dreams: [
          pdeDream('new2', 'Kariyer stresi rüyası.', at: recent),
        ],
      ),
      now: now,
    );
    expect(p.personalizationThemes.first, 'kariyer');
    expect(
      DiscoveryRecency.weight(recent, now),
      greaterThan(DiscoveryRecency.weight(old, now)),
    );
  });
}
