/// Phase 3/4 matrix — honesty gates across surfaces and failures.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/astrology/services/astrology_personalization.dart';
import 'package:oracly_new/features/personal_discovery/copy/personal_theme_copy.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_profile.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_sources.dart';
import 'package:oracly_new/features/personal_discovery/services/discovery_or_context.dart';
import 'package:oracly_new/features/personal_discovery/services/personal_discovery_profile_builder.dart';
import 'package:oracly_new/features/star_map/models/star_map_reading.dart';
import 'package:oracly_new/features/star_map/services/star_map_personalization.dart';

import 'pde_test_fixtures.dart';

void main() {
  final now = DateTime(2026, 8, 15);

  test('I missing birth date stays null', () {
    final p = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(readings: [pdeTarot('r1', 'Sakin.')]),
      now: now,
    );
    expect(p.birthDate, isNull);
    expect(p.zodiacSign, isNull);
  });

  test('J missing history keeps honest empty states', () {
    expect(PersonalDiscoveryProfile.empty.hasHistory, isFalse);
    expect(DiscoveryOrContext.compact(PersonalDiscoveryProfile.empty), isNull);
    expect(PersonalThemeCopy.insufficient, contains('yeterli'));
  });

  test('K coffee provider failure leaves no invented coffee themes', () {
    final p = PersonalDiscoveryProfileBuilder.from(
      const PersonalDiscoverySources(),
      now: now,
    );
    expect(p.coffeeCount, 0);
    expect(p.coffeeThemes, isEmpty);
  });

  test('L palm provider failure leaves no invented palm themes', () {
    final p = PersonalDiscoveryProfileBuilder.from(
      const PersonalDiscoverySources(),
      now: now,
    );
    expect(p.palmCount, 0);
    expect(p.palmThemes, isEmpty);
  });

  test('M soulmate persistence absent stays zero', () {
    final p = PersonalDiscoveryProfileBuilder.from(
      const PersonalDiscoverySources(),
      now: now,
    );
    expect(p.soulmateGenerations, 0);
  });

  test('N OR context absent when no themes', () {
    expect(DiscoveryOrContext.compact(PersonalDiscoveryProfile.empty), isNull);
  });

  test('O OR context present is compact and observational', () {
    final p = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [pdeTarot('r1', 'Değişim kapıda.')],
        coffee: [pdeCoffee('c1', 'Bu değişim yumuşak.')],
        dreams: [pdeDream('d1', 'Rüyada değişim vardı.')],
      ),
      now: now,
    );
    final ctx = DiscoveryOrContext.compact(p)!;
    expect(ctx, contains('değişim'));
    expect(ctx.toLowerCase(), isNot(contains('sen sürekli')));
    expect(ctx, contains('Son dönemde'));
    expect(ctx, isNot(contains('Son gözlemler')));
    expect(ctx, isNot(contains(' alan')));
  });

  test('P privacy — profile fields never carry secrets', () {
    final p = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(coffee: [pdeCoffee('c1', 'Sakin fincan.')]),
      now: now,
    );
    final blob = p.observations.toString();
    expect(blob, isNot(contains('sk-')));
    expect(blob, isNot(contains('Bearer')));
    expect(blob, isNot(contains('/tmp/secret')));
  });

  test('astrology love/career only when matching themes exist', () {
    final careerOnly = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [pdeTarot('r1', 'Kariyer görünüyor.')],
        coffee: [pdeCoffee('c1', 'Kariyer sabır ister.')],
      ),
      now: now,
    );
    final over = AstrologyPersonalization.overlay(
      base: pdeAstroBase,
      signName: 'Aslan',
      profile: careerOnly,
      day: now,
    );
    expect(over.career.toLowerCase(), contains('kariyer'));
    expect(over.love, isEmpty);
  });

  test('yıldızname insufficient without cross-modal themes', () {
    const base = StarMapReading(
      overview: StarMapOverview(
        whatItSays: 'Gökyüzü sakin.',
        dominantEnergy: 'Dinginlik',
        mainMessage: 'Yavaşla.',
      ),
      skyMessage: StarMapSkyMessage(
        today: 'Nefes.',
        interpretation: 'Sakin.',
        advice: 'Bir adım.',
      ),
      karmic: StarMapKarmicReading(
        theme: 'Dinlen',
        learning: 'Yavaşla.',
        interpretation: 'Yorum.',
        takeaway: 'Bir adım.',
      ),
      planets: [],
    );
    final empty = StarMapPersonalization.overlay(
      base: base,
      discovery: PersonalDiscoveryProfile.empty,
      day: now,
    );
    expect(empty.recurringThemesLine, PersonalThemeCopy.insufficient);
  });
}
