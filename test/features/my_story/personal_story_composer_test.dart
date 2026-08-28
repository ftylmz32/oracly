/// BENİM HİKÂYEM — real evidence only, no overclaiming.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/discovery_journal/copy/discovery_journal_copy.dart';
import 'package:oracly_new/features/my_story/services/personal_story_composer.dart';
import 'package:oracly_new/features/personal_discovery/copy/personal_theme_copy.dart';
import 'package:oracly_new/features/personal_discovery/models/cross_discovery_insight.dart';
import 'package:oracly_new/features/personal_discovery/models/discovery_theme_strength.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_profile.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_sources.dart';
import 'package:oracly_new/features/personal_discovery/models/theme_over_time_period.dart';
import 'package:oracly_new/features/personal_discovery/services/personal_discovery_profile_builder.dart';

import '../personal_discovery/pde_test_fixtures.dart';

CrossDiscoveryInsight _cross(String theme, List<String> sources) {
  return CrossDiscoveryInsight(
    theme: theme,
    sources: sources,
    confidence: DiscoveryThemeStrength.recurring,
    lastObserved: DateTime(2026, 8, 18),
    sourceCount: sources.length,
    discoveryCount: 2,
    recencyWeight: 0.9,
  );
}

void main() {
  final now = DateTime(2026, 8, 19, 12);

  test('empty profile stays honest — no invented story', () {
    final story = PersonalStoryComposer.compose(PersonalDiscoveryProfile.empty);
    expect(story.narrative, PersonalThemeCopy.insufficient);
    expect(story.periods, isEmpty);
    expect(story.hasRecurringEvidence, isFalse);
    expect(story.sourcesLine, isNull);
  });

  test('history without cross-modal themes accumulates quietly', () {
    final profile = PersonalDiscoveryProfile(
      tarotCount: 2,
      crossInsights: const [],
    );
    final story = PersonalStoryComposer.compose(profile);
    expect(story.narrative, PersonalThemeCopy.accumulating);
    expect(story.hasRecurringEvidence, isFalse);
  });

  test('cross-modal recurring themes use observational copy', () {
    final profile = PersonalDiscoveryProfile(
      tarotCount: 1,
      coffeeCount: 1,
      crossInsights: [
        _cross('karar verme', const ['tarot', 'coffee']),
      ],
    );
    final story = PersonalStoryComposer.compose(profile);
    expect(story.narrative, contains('yeniden karşına çıkıyor'));
    expect(story.narrative, contains('karar verme'));
    expect(story.narrative, isNot(contains('Sen böyle')));
    expect(story.narrative.toLowerCase(), isNot(contains('memory')));
    expect(story.narrative.toLowerCase(), isNot(contains('embedding')));
    expect(story.hasRecurringEvidence, isTrue);
    expect(
      story.sourcesLine,
      DiscoveryJournalCopy.sourcesLine(['coffee', 'tarot']),
    );
  });

  test('period chapters appear only when time builder has enough data', () {
    final built = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [
          pdeTarot('r1', 'Karar verme zamanı.', at: now.subtract(const Duration(days: 6))),
          pdeTarot('r2', 'Karar verme sakin.', at: now.subtract(const Duration(days: 5))),
        ],
        coffee: [
          pdeCoffee('c1', 'Değişim yumuşak.', at: now.subtract(const Duration(days: 2))),
          pdeCoffee('c2', 'Değişim kapıda.', at: now.subtract(const Duration(days: 1))),
        ],
      ),
      now: now,
    );
    final story = PersonalStoryComposer.compose(built, now: now);
    expect(
      story.periods.any((p) => p.period == ThemeOverTimePeriod.days7),
      isTrue,
    );
    expect(story.periods.first.narrative.trim(), isNotEmpty);
  });

  test('sources line hidden for single modality', () {
    final profile = PersonalDiscoveryProfile(
      tarotCount: 3,
      crossInsights: [
        _cross('değişim', const ['tarot']),
      ],
    );
    final story = PersonalStoryComposer.compose(profile);
    expect(story.sourcesLine, isNull);
  });
}
