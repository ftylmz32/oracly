/// PDE v1 — privacy + Astrology / Yıldızname / Daily / Journal surfaces.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/astrology/services/astrology_personalization.dart';
import 'package:oracly_new/features/daily_message/services/daily_message_service.dart';
import 'package:oracly_new/features/personal_discovery/copy/personal_theme_copy.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_profile.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_sources.dart';
import 'package:oracly_new/features/personal_discovery/services/personal_discovery_profile_builder.dart';
import 'package:oracly_new/features/star_map/models/star_map_reading.dart';
import 'package:oracly_new/features/star_map/services/star_map_personalization.dart';

import 'pde_test_fixtures.dart';

void main() {
  test('10 privacy — profile never stores raw image paths', () {
    final p = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(coffee: [pdeCoffee('c1', 'Sakin fincan.')]),
    );
    final blob = [
      p.coffeeThemes,
      p.themeSignals.map((s) => s.label),
      p.birthPlace,
    ].toString();
    expect(blob, isNot(contains('/tmp/')));
    expect(blob, isNot(contains('secret-cup')));
    expect(blob, isNot(contains('sk-')));
    expect(blob, isNot(contains('Bearer')));
  });

  test('11 daily message varies by day without random noise', () {
    final themes = ['kariyer', 'değişim'];
    final a = DailyMessageService.forDay(
      day: DateTime(2026, 8, 14),
      profileName: 'Fatih',
      themes: themes,
    );
    final b = DailyMessageService.forDay(
      day: DateTime(2026, 8, 15),
      profileName: 'Fatih',
      themes: themes,
    );
    expect(a.text, isNot(equals(b.text)));
    final bare = DailyMessageService.forDay(
      day: DateTime(2026, 8, 14),
      profileName: 'Fatih',
    );
    expect(bare.text.contains('tekrar eden'), isFalse);
  });

  test('12 astrology personalizes only with cross-modal themes', () {
    final single = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [
          pdeTarot('r1', 'Değişim kapıda.'),
          pdeTarot('r2', 'Bu değişim yumuşak.'),
        ],
      ),
    );
    final overSingle = AstrologyPersonalization.overlay(
      base: pdeAstroBase,
      signName: 'Aslan',
      profile: single,
      day: DateTime(2026, 8, 14),
    );
    expect(overSingle.innerTheme, PersonalThemeCopy.insufficient);

    final cross = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [pdeTarot('r1', 'Kariyer görünüyor.')],
        coffee: [pdeCoffee('c1', 'Kariyer sabır ister.')],
      ),
    );
    final overCross = AstrologyPersonalization.overlay(
      base: pdeAstroBase,
      signName: 'Aslan',
      profile: cross,
      day: DateTime(2026, 8, 14),
    );
    expect(overCross.innerTheme, contains('kariyer'));
    expect(overCross.innerTheme.toLowerCase(), isNot(contains('evren')));
  });

  test('13 yıldızname stays honest without cross-modal themes', () {
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
        promptQuestion: 'Ne istiyorsun?',
      ),
      planets: [],
    );
    final empty = StarMapPersonalization.overlay(
      base: base,
      discovery: PersonalDiscoveryProfile.empty,
      day: DateTime(2026, 8, 14),
    );
    expect(empty.recurringThemesLine, PersonalThemeCopy.insufficient);

    final cross = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [pdeTarot('r1', 'Değişim var.')],
        dreams: [pdeDream('d1', 'Değişim rüyası.')],
      ),
    );
    final filled = StarMapPersonalization.overlay(
      base: base,
      discovery: cross,
      day: DateTime(2026, 8, 14),
    );
    expect(filled.recurringThemesLine.toLowerCase(), contains('değişim'));
    expect(filled.recurringThemesLine, contains('yeniden'));
  });

  test('14 discovery journal theme copy is observational', () {
    final line = PersonalThemeCopy.crossModal(['kariyer', 'değişim']);
    expect(line, contains('yeniden karşına çıkıyor'));
    expect(line.toLowerCase(), isNot(contains('evren sana')));
  });
}
