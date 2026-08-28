/// Personal Discovery V2 — weight, cross-modal, anti-repetition, OR, daily.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/daily_message/services/daily_message_service.dart';
import 'package:oracly_new/features/discovery_journal/services/discovery_journal_aggregator.dart';
import 'package:oracly_new/features/personal_discovery/copy/personal_theme_copy.dart';
import 'package:oracly_new/features/personal_discovery/models/discovery_theme_strength.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_sources.dart';
import 'package:oracly_new/features/personal_discovery/models/surfaced_theme_record.dart';
import 'package:oracly_new/features/personal_discovery/services/discovery_or_context.dart';
import 'package:oracly_new/features/personal_discovery/services/personal_discovery_profile_builder.dart';
import 'package:oracly_new/features/personal_discovery/services/personal_insight_service.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';

import 'pde_test_fixtures.dart';

void main() {
  final now = DateTime(2026, 8, 15);

  test('A empty profile invents nothing', () {
    final p = PersonalDiscoveryProfileBuilder.from(
      const PersonalDiscoverySources(),
      now: now,
    );
    expect(p.themeSignals, isEmpty);
    expect(p.personalizationThemes, isEmpty);
    expect(DiscoveryOrContext.compact(p), isNull);
    expect(DiscoveryJournalAggregator.merge(), isEmpty);
  });

  test('B one discovery stays observed, not a trait', () {
    final p = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [pdeTarot('r1', 'Aşk konusunda sakin dur.')],
      ),
      now: now,
    );
    expect(p.themeSignals.single.strength, DiscoveryThemeStrength.observed);
    expect(p.recurringThemes, isEmpty);
    expect(p.personalizationThemes, isEmpty);
    expect(DiscoveryOrContext.compact(p), isNull);
  });

  test('C same theme in two sources is recurring cross-modal', () {
    final p = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [pdeTarot('r1', 'Değişim kapıda.')],
        coffee: [pdeCoffee('c1', 'Bu değişim yumuşak.')],
      ),
      now: now,
    );
    final signal = p.themeSignals.firstWhere((s) => s.label == 'değişim');
    expect(signal.strength, DiscoveryThemeStrength.recurring);
    expect(signal.sources, containsAll(['coffee', 'tarot']));
    expect(
      PersonalThemeCopy.crossModal(const ['değişim']),
      contains('yeniden karşına çıkıyor'),
    );
    expect(
      PersonalThemeCopy.crossModal(const ['değişim', 'karar verme']),
      contains('yeniden karşına çıkıyor'),
    );
  });

  test('D three recent sources mark strong', () {
    final p = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [pdeTarot('r1', 'Değişim kapıda.')],
        coffee: [pdeCoffee('c1', 'Bu değişim yumuşak.')],
        dreams: [pdeDream('d1', 'Rüyada değişim vardı.')],
      ),
      now: now,
    );
    final signal = p.themeSignals.firstWhere((s) => s.label == 'değişim');
    expect(signal.strength, DiscoveryThemeStrength.strong);
    expect(signal.discoveryCount, 3);
  });

  test('E overused love yields a supported alternative', () {
    final p = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [
          pdeTarot('r1', 'Aşk ve iletişim iç içe.'),
        ],
        coffee: [pdeCoffee('c1', 'Aşk teması duruyor.')],
        dreams: [pdeDream('d1', 'Konuşmak ve iletişim kaldı.')],
      ),
      now: now,
    );
    final insights = PersonalInsightService.fromProfile(
      p,
      day: now,
      surface: 'daily',
      recent: [
        SurfacedThemeRecord(
          theme: 'aşk',
          surface: 'daily',
          at: now.subtract(const Duration(hours: 3)),
        ),
      ],
    );
    expect(insights.map((i) => i.theme), isNot(contains('aşk')));
    expect(insights.map((i) => i.theme), contains('iletişim'));
  });

  test('F overused theme without alternative stays neutral', () {
    final p = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [pdeTarot('r1', 'Aşk görünüyor.')],
        coffee: [pdeCoffee('c1', 'Aşk yumuşak.')],
      ),
      now: now,
    );
    final insights = PersonalInsightService.fromProfile(
      p,
      day: now,
      surface: 'daily',
      recent: [
        SurfacedThemeRecord(
          theme: 'aşk',
          surface: 'daily',
          at: now.subtract(const Duration(hours: 1)),
        ),
      ],
    );
    expect(insights, isEmpty);
    final daily = DailyMessageService.forDay(
      day: now,
      profileName: 'Fatih',
      insight: null,
    );
    expect(daily.theme, isNull);
    expect(daily.text.contains('aşk'), isFalse);
  });

  test('G recent theme outranks an old one', () {
    final p = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [
          pdeTarot('old', 'Değişim kapıda.', at: DateTime(2026, 1, 2)),
          pdeTarot('new', 'Karar alma zamanı.', at: DateTime(2026, 8, 14)),
        ],
        coffee: [
          pdeCoffee('oldc', 'Bu değişim yumuşak.', at: DateTime(2026, 1, 3)),
        ],
        dreams: [
          pdeDream('d1', 'Karar vermek içinden geldi.', at: DateTime(2026, 8, 14)),
        ],
      ),
      now: now,
    );
    expect(p.personalizationThemes.first, 'karar verme');
    expect(DiscoveryOrContext.themeLabels(p).first, 'karar verme');
  });

  test('daily copy changes with the calendar day', () {
    final a = DailyMessageService.forDay(
      day: DateTime(2026, 8, 14),
      profileName: 'Fatih',
      themes: const ['değişim'],
    );
    final b = DailyMessageService.forDay(
      day: DateTime(2026, 8, 15),
      profileName: 'Fatih',
      themes: const ['değişim'],
    );
    expect(a.text, isNot(equals(b.text)));
  });

  test('OR compact is max three themes, includes style, never dumps history', () {
    final p = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        settings: const PersonalizationSettings(
          aiPersonality: AiPersonality.gentle,
        ),
        readings: [
          pdeTarot('r1', 'Değişim ve iletişim ve karar alma.'),
        ],
        coffee: [
          pdeCoffee('c1', 'Değişim, iletişim ve karar vermek.'),
        ],
        dreams: [
          pdeDream('d1', 'Aile içinde değişim, iletişim, karar alma.'),
        ],
      ),
      now: now,
    );
    final ctx = DiscoveryOrContext.compact(p)!;
    expect(DiscoveryOrContext.themeLabels(p), hasLength(lessThanOrEqualTo(3)));
    expect(ctx.toLowerCase(), contains('üslup'));
    expect(ctx.toLowerCase(), contains('sakin'));
    expect(ctx, isNot(contains('aile içinde')));
    expect(ctx.toLowerCase(), isNot(contains('kesin')));
  });

  test('journal lists only real entries with source dates', () {
    final entries = DiscoveryJournalAggregator.merge(
      readings: [pdeTarot('r1', 'Sakin.')],
      coffee: [pdeCoffee('c1', 'Yol görünür.')],
    );
    expect(entries, hasLength(2));
    expect(entries.map((e) => e.id), containsAll(['r1', 'c1']));
  });
}
