/// Phase 2 — themes are observational and require recurrence.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/features/personal_discovery/copy/personal_theme_copy.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_sources.dart';
import 'package:oracly_new/features/personal_discovery/services/personal_discovery_profile_builder.dart';
import 'package:oracly_new/features/personal_discovery/services/personal_theme_extractor.dart';

import 'pde_test_fixtures.dart';

ReadingModel _reading(String id, String summary) => ReadingModel(
      id: id,
      cardId: 0,
      cardName: 'The Moon',
      cardImageAsset: 'a',
      spreadType: 'Tek Kart',
      aiSummary: summary,
      createdAt: DateTime(2026, 8, 10),
    );

void main() {
  test('a single mention is not treated as recurring', () {
    expect(
      PersonalThemeExtractor.labelsIn(['Sınırlarını korumak iyi gelir.']),
      isEmpty,
    );
  });

  test('two mentions of the same theme become a recurring label', () {
    expect(
      PersonalThemeExtractor.labelsIn([
        'Sınırlarını nazikçe tut.',
        'Bu açılımda sınır teması yeniden görünüyor.',
      ]),
      ['sınırlar'],
    );
  });

  test('copy stays observational and never diagnoses the person', () {
    final line = PersonalThemeCopy.recurring(['sınırlar', 'değişim']);
    expect(line, contains('tekrar eden'));
    expect(line.toLowerCase(), isNot(contains('sen şöylesin')));
    expect(line.toLowerCase(), isNot(contains('kişiliğin')));
    expect(PersonalThemeCopy.recurring(const []), PersonalThemeCopy.insufficient);
  });

  test('profile tarot themes stay empty without recurrence', () {
    final profile = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [_reading('r1', 'Cesaretle bir adım at.')],
      ),
    );
    expect(profile.tarotThemes, isEmpty);
    expect(profile.recurringThemes, isEmpty);
  });

  test('two tarot summaries can surface a real tarot theme', () {
    final profile = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [
          _reading('r1', 'Değişim kapıda; yavaş ilerle.'),
          _reading('r2', 'Bu değişim bir kapanış gibi duruyor.'),
        ],
      ),
    );
    expect(profile.tarotThemes, contains('değişim'));
    expect(profile.recurringThemes, isEmpty);
    expect(profile.personalizationThemes, isEmpty);
  });

  test('top recurring themes are capped at three and prefer diverse recent ones', () {
    final now = DateTime(2026, 8, 15);
    final profile = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [
          pdeTarot('r1', 'Değişim ve iletişim görünür.', at: now),
          pdeTarot('r2', 'Değişim yeniden beliriyor.', at: now),
          pdeTarot('r3', 'Aşk uzaktan geçiyor.', at: now.subtract(const Duration(days: 120))),
        ],
        coffee: [
          pdeCoffee('c1', 'Karar verme ve değişim birlikte akıyor.', at: now),
          pdeCoffee('c2', 'İletişim daha açık ilerliyor.', at: now.subtract(const Duration(days: 3))),
          pdeCoffee('c3', 'Aşk biraz daha sessiz.', at: now.subtract(const Duration(days: 110))),
        ],
        dreams: [
          pdeDream('d1', 'Karar verme kapıda gibi.', at: now.subtract(const Duration(days: 6))),
          pdeDream('d2', 'İletişim tekrar açılıyor.', at: now.subtract(const Duration(days: 5))),
        ],
      ),
      now: now,
    );
    expect(profile.crossInsights.length, lessThanOrEqualTo(3));
    expect(profile.crossInsights.map((i) => i.theme).toList(), [
      'iletişim',
      'değişim',
      'karar verme',
    ]);
  });
}
