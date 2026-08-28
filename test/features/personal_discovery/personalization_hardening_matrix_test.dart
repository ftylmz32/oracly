/// Final personalization matrix — real evidence only, no UI.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/personal_discovery/copy/personal_theme_copy.dart';
import 'package:oracly_new/features/personal_discovery/models/discovery_theme_strength.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_sources.dart';
import 'package:oracly_new/features/personal_discovery/models/surfaced_theme_record.dart';
import 'package:oracly_new/features/personal_discovery/services/discovery_or_context.dart';
import 'package:oracly_new/features/personal_discovery/services/personal_discovery_profile_builder.dart';
import 'package:oracly_new/features/personal_discovery/services/personal_insight_service.dart';

import 'pde_test_fixtures.dart';

void main() {
  final now = DateTime(2026, 8, 15);
  const fear = ['korkuyorsun', 'kişiliğin', 'sen şöylesin'];

  test('empty history does not fake personalization', () {
    final p = PersonalDiscoveryProfileBuilder.from(
      const PersonalDiscoverySources(),
      now: now,
    );
    expect(p.hasHistory, isFalse);
    expect(p.personalizationThemes, isEmpty);
    expect(DiscoveryOrContext.compact(p), isNull);
    expect(PersonalThemeCopy.insufficient, 'Henüz yeterli keşif birikmedi.');
    expect(PersonalThemeCopy.crossModal(const []), PersonalThemeCopy.insufficient);
  });

  test('one old record stays weak', () {
    final p = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        coffee: [
          pdeCoffee(
            'old',
            'Bu değişim yumuşak.',
            at: DateTime(2026, 1, 2),
          ),
        ],
      ),
      now: now,
    );
    expect(p.themeSignals.single.strength, DiscoveryThemeStrength.observed);
    expect(p.personalizationThemes, isEmpty);
    expect(DiscoveryOrContext.compact(p), isNull);
  });

  test('two sources make one observational cross-modal theme', () {
    final p = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        coffee: [pdeCoffee('c1', 'Bu değişim yumuşak.')],
        dreams: [pdeDream('d1', 'Rüyada bir hareket vardı.')],
      ),
      now: now,
    );
    expect(p.personalizationThemes, ['değişim']);
    expect(
      PersonalThemeCopy.crossModal(p.personalizationThemes),
      contains('yeniden karşına çıkıyor'),
    );
  });

  test('three recent independent sources are stronger', () {
    final p = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        coffee: [pdeCoffee('c1', 'Bu değişim yumuşak.')],
        dreams: [pdeDream('d1', 'Rüyada bir hareket vardı.')],
        palm: [pdePalm('p1', 'Avuçta bir dönüşüm izi.')],
      ),
      now: now,
    );
    final change = p.crossInsights.firstWhere((i) => i.theme == 'değişim');
    expect(change.confidence, DiscoveryThemeStrength.strong);
    expect(change.sourceCount, 3);
    expect(change.sources, containsAll(['coffee', 'dream', 'palm']));
  });

  test('recent evidence outranks old evidence', () {
    final p = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        coffee: [
          pdeCoffee('old', 'Bu değişim yumuşak.', at: DateTime(2026, 1, 3)),
        ],
        dreams: [
          pdeDream('oldd', 'Rüyada değişim vardı.', at: DateTime(2026, 1, 4)),
        ],
        palm: [
          pdePalm('new', 'Avuçta dinlenme izi.', at: DateTime(2026, 8, 14)),
        ],
        astrology: [
          pdeSky('newsky', 'Bugün dinlenmek iyi gelir.', at: DateTime(2026, 8, 14)),
        ],
      ),
      now: now,
    );
    expect(p.personalizationThemes.first, 'dinlenme');
  });

  test('repeated theme yields a real alternative, never an invented one', () {
    final p = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        coffee: [pdeCoffee('c1', 'Değişim ve dinlenme birlikte.')],
        dreams: [pdeDream('d1', 'Rüyada değişim ve dinlenmek vardı.')],
      ),
      now: now,
    );
    final insights = PersonalInsightService.fromProfile(
      p,
      day: now,
      surface: 'daily',
      recent: [
        SurfacedThemeRecord(
          theme: 'değişim',
          surface: 'daily',
          at: now.subtract(const Duration(hours: 2)),
        ),
      ],
    );
    expect(insights.map((i) => i.theme), isNot(contains('değişim')));
    expect(insights.map((i) => i.theme), contains('dinlenme'));
    expect(insights.map((i) => i.theme), isNot(contains('cesaret')));
  });

  test('conflicting themes stay separate observations', () {
    final p = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        coffee: [pdeCoffee('c1', 'Bu değişim yumuşak.')],
        dreams: [pdeDream('d1', 'Rüyada bir hareket vardı.')],
        conversations: [pdeOr('or1', 'Karar vermek içinden geldi.')],
        palm: [pdePalm('p1', 'Avuçta dinlenme izi.')],
        astrology: [pdeSky('a1', 'Bugün dinlenmek iyi gelir.')],
      ),
      now: now,
    );
    expect(p.personalizationThemes, containsAll(['değişim', 'dinlenme']));
    final line = PersonalThemeCopy.crossModal(p.personalizationThemes);
    expect(line, contains('yeniden karşına çıkıyor'));
    for (final word in fear) {
      expect(line.toLowerCase(), isNot(contains(word)));
    }
    expect(DiscoveryOrContext.compact(p)!.toLowerCase(), isNot(contains('korkuyorsun')));
  });
}
