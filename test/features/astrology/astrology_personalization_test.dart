/// Phase 3 — sun sign + real cross-modal themes only; no invented natal data.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/astrology/services/astrology_daily_reading_service.dart';
import 'package:oracly_new/features/astrology/services/astrology_personalization.dart';
import 'package:oracly_new/features/content/astrology/data/astrology_content_catalogue.dart';
import 'package:oracly_new/features/personal_discovery/copy/personal_theme_copy.dart';
import 'package:oracly_new/features/personal_discovery/models/cross_discovery_insight.dart';
import 'package:oracly_new/features/personal_discovery/models/discovery_theme_strength.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_profile.dart';

const _forbidden = [
  'ay burcu',
  'yükselen',
  'evler',
  'gezegen',
  'natal',
  'gezegen açı',
];

CrossDiscoveryInsight _insight(String theme, List<String> sources) {
  return CrossDiscoveryInsight(
    theme: theme,
    sources: sources,
    confidence: DiscoveryThemeStrength.recurring,
    lastObserved: DateTime(2026, 8, 13),
    sourceCount: sources.length,
    discoveryCount: 2,
    recencyWeight: 1,
  );
}

void main() {
  final aries = AstrologyContentCatalogue.signById('aries')!;
  final profile = PersonalDiscoveryProfile(
    crossInsights: [
      _insight('ilişki', const ['tarot', 'dream']),
      _insight('kariyer', const ['tarot', 'coffee']),
    ],
  );

  test('without history, inner theme stays honestly empty', () {
    final reading = AstrologyDailyReadingService.build(
      aries,
      now: DateTime(2026, 8, 13),
    );
    expect(reading.innerTheme, PersonalThemeCopy.insufficient);
    for (final word in _forbidden) {
      expect(reading.overall.toLowerCase(), isNot(contains(word)));
      expect(reading.innerTheme.toLowerCase(), isNot(contains(word)));
    }
  });

  test('real themes personalize love, career, and inner theme', () {
    final reading = AstrologyDailyReadingService.build(
      aries,
      now: DateTime(2026, 8, 13),
      profile: profile,
    );
    expect(reading.overall.toLowerCase(), contains('koç'));
    expect(reading.overall.toLowerCase(), contains('gökyüzü'));
    expect(reading.overall, isNot(contains('Bugün senin için asıl mesele ilişki')));
    expect(reading.love, isNot(contains('Bugün senin için asıl mesele')));
    expect(reading.innerTheme, contains('yeniden karşına çıkıyor'));
    expect(reading.love.toLowerCase(), contains('ilişki'));
    expect(reading.career.toLowerCase(), contains('kariyer'));
  });

  test('same user sees different copy on different days', () {
    final a = AstrologyDailyReadingService.build(
      aries,
      now: DateTime(2026, 8, 13),
      profile: profile,
    );
    final b = AstrologyDailyReadingService.build(
      aries,
      now: DateTime(2026, 8, 14),
      profile: profile,
    );
    expect(a.innerTheme, isNot(equals(b.innerTheme)));
  });

  test('relationship and direction theme gates stay honest', () {
    expect(
      AstrologyPersonalization.hasRelationshipTheme(const ['ilişki']),
      isTrue,
    );
    expect(
      AstrologyPersonalization.hasDirectionTheme(const ['kariyer']),
      isTrue,
    );
    expect(
      AstrologyPersonalization.hasRelationshipTheme(const ['kariyer']),
      isFalse,
    );
    expect(AstrologyPersonalization.hasDirectionTheme(const []), isFalse);
  });

  test('never invents moon, ascendant, houses, or planets', () {
    final reading = AstrologyDailyReadingService.build(
      aries,
      now: DateTime(2026, 8, 13),
      profile: profile,
    );
    final blob = [
      reading.overall,
      reading.love,
      reading.career,
      reading.innerTheme,
    ].join(' ').toLowerCase();
    for (final word in _forbidden) {
      expect(blob, isNot(contains(word)));
    }
  });
}
