/// PDE v1 — profile strength and cross-modal evidence.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/models/birth_profile.dart';
import 'package:oracly_new/features/personal_discovery/copy/personal_theme_copy.dart';
import 'package:oracly_new/features/personal_discovery/models/discovery_theme_strength.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_sources.dart';
import 'package:oracly_new/features/personal_discovery/services/personal_discovery_profile_builder.dart';
import 'package:oracly_new/features/personal_discovery/services/personal_theme_extractor.dart';

import 'pde_test_fixtures.dart';

void main() {
  test('1 empty profile stays empty', () {
    final p = PersonalDiscoveryProfileBuilder.from(
      const PersonalDiscoverySources(),
    );
    expect(p.birthDate, isNull);
    expect(p.themeSignals, isEmpty);
    expect(p.personalizationThemes, isEmpty);
    expect(p.hasHistory, isFalse);
  });

  test('2 birth date only — sun real, no invented themes', () {
    final p = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        birth: BirthProfile(
          birthDate: DateTime(1990, 3, 21),
          birthPlace: 'İzmir',
        ),
      ),
    );
    expect(p.hasBirth, isTrue);
    expect(p.zodiacSign, isNotNull);
    expect(p.recurringThemes, isEmpty);
    expect(p.crossModalThemes, isEmpty);
  });

  test('3 one discovery only — observed, not recurring', () {
    final p = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [pdeTarot('r1', 'Kariyer yolunda sakin ilerle.')],
      ),
    );
    expect(p.tarotThemes, isEmpty);
    expect(p.recurringThemes, isEmpty);
    expect(p.themeSignals.single.strength, DiscoveryThemeStrength.observed);
  });

  test('4 same theme in two sources becomes cross-modal recurring', () {
    final p = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [pdeTarot('r1', 'Kariyer teması görünüyor.')],
        coffee: [pdeCoffee('c1', 'İş hayatında kariyer için sabır.')],
      ),
    );
    expect(p.crossModalThemes, contains('kariyer'));
    final signal = p.themeSignals.firstWhere((s) => s.label == 'kariyer');
    expect(signal.strength, DiscoveryThemeStrength.recurring);
    expect(signal.sources, containsAll(['coffee', 'tarot']));
  });

  test('5 three sources mark strong when count allows', () {
    final p = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [pdeTarot('r1', 'Değişim kapıda.')],
        coffee: [pdeCoffee('c1', 'Bu değişim yumuşak.')],
        dreams: [pdeDream('d1', 'Rüyada değişim vardı.')],
      ),
    );
    final signal = p.themeSignals.firstWhere((s) => s.label == 'değişim');
    expect(signal.strength, DiscoveryThemeStrength.strong);
  });

  test('6 no recurring themes when history lacks evidence', () {
    final p = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [pdeTarot('r1', 'Sakin bir açılım.')],
        coffee: [pdeCoffee('c1', 'Durulmak yeterli.')],
      ),
    );
    expect(p.recurringThemes, isEmpty);
  });

  test('7 single-modality repeats stay observed, not a trait', () {
    final p = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [
          pdeTarot('r1', 'Değişim kapıda.'),
          pdeTarot('r2', 'Bu değişim bir kapanış.'),
        ],
      ),
    );
    expect(p.tarotThemes, contains('değişim'));
    expect(p.personalizationThemes, isEmpty);
    expect(p.recurringThemes, isEmpty);
    expect(
      p.themeSignals.firstWhere((s) => s.label == 'değişim').strength,
      DiscoveryThemeStrength.observed,
    );
  });

  test('8 missing birth date leaves zodiac null', () {
    final p = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(readings: [pdeTarot('r1', 'Sakin.')]),
    );
    expect(p.birthDate, isNull);
    expect(p.zodiacSign, isNull);
  });

  test('9 missing history keeps honest copy', () {
    expect(PersonalThemeCopy.recurring(const []), PersonalThemeCopy.insufficient);
    expect(
      PersonalThemeCopy.personalInsight(const [], DateTime(2026, 8, 14)),
      PersonalThemeCopy.insufficient,
    );
  });

  test('single record never becomes recurring', () {
    expect(
      PersonalThemeExtractor.labelsIn(['Sınırlarını korumak iyi gelir.']),
      isEmpty,
    );
    final signals = PersonalThemeExtractor.aggregate({
      'tarot': ['Sınırlarını korumak iyi gelir.'],
    });
    expect(signals.single.strength, DiscoveryThemeStrength.observed);
  });
}
