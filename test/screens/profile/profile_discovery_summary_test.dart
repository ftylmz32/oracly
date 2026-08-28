/// Honest Profile discovery summary — real recurring themes only.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/personal_discovery/models/cross_discovery_insight.dart';
import 'package:oracly_new/features/personal_discovery/models/discovery_theme_strength.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_profile.dart';
import 'package:oracly_new/features/personal_discovery/providers/personal_discovery_providers.dart';
import 'package:oracly_new/screens/profile/copy/profile_copy.dart';
import 'package:oracly_new/screens/profile/reference/profile_discovery_insight_card.dart';
import 'package:oracly_new/screens/profile/reference/profile_discovery_summary.dart';

void main() {
  CrossDiscoveryInsight recurring(String theme) {
    return CrossDiscoveryInsight(
      theme: theme,
      sources: const ['tarot', 'coffee'],
      confidence: DiscoveryThemeStrength.recurring,
      lastObserved: DateTime(2026, 8, 10),
      sourceCount: 2,
      discoveryCount: 3,
      recencyWeight: 0.9,
    );
  }

  test('formats real recurring themes, date, and count', () {
    final profile = PersonalDiscoveryProfile(
      lastUpdated: DateTime(2026, 8, 10),
      tarotCount: 4,
      coffeeCount: 2,
      crossInsights: [
        recurring('değişim'),
        recurring('iletişim'),
        recurring('karar verme'),
      ],
    );
    expect(
      ProfileDiscoverySummary.themesLine(profile),
      'Değişim · İletişim · Karar Verme',
    );
    expect(ProfileDiscoverySummary.count(profile), 6);
    expect(
      ProfileDiscoverySummary.metaLine(profile),
      '6 keşif · 10 Ağustos 2026',
    );
  });

  test('hides themes and meta when nothing real exists', () {
    expect(
      ProfileDiscoverySummary.themesLine(PersonalDiscoveryProfile.empty),
      isEmpty,
    );
    expect(
      ProfileDiscoverySummary.metaLine(PersonalDiscoveryProfile.empty),
      isNull,
    );
  });

  test('ignores observed-only themes', () {
    final profile = PersonalDiscoveryProfile(
      tarotCount: 1,
      lastUpdated: DateTime(2026, 8, 10),
      crossInsights: [
        CrossDiscoveryInsight(
          theme: 'değişim',
          sources: const ['tarot'],
          confidence: DiscoveryThemeStrength.observed,
          lastObserved: DateTime(2026, 8, 10),
          sourceCount: 1,
          discoveryCount: 1,
          recencyWeight: 0.9,
        ),
      ],
    );
    expect(ProfileDiscoverySummary.themesLine(profile), isEmpty);
    expect(
      ProfileDiscoverySummary.metaLine(profile),
      '1 keşif · 10 Ağustos 2026',
    );
  });

  test('chip meta stays human: count, date, sources', () {
    final meta = ProfileDiscoverySummary.chipMeta(recurring('değişim'));
    expect(meta, contains('3 keşif'));
    expect(meta, contains('10 Ağustos 2026'));
    expect(meta, contains('Tarot'));
    expect(meta, contains('Kahve'));
    expect(meta, isNot(contains('alanda')));
    expect(meta.toLowerCase(), isNot(contains('sourcecount')));
    expect(meta.toLowerCase(), isNot(contains('recency')));
  });

  testWidgets('card shows honest empty when no recurring themes', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          personalDiscoveryProfileProvider.overrideWith(
            (ref) async => PersonalDiscoveryProfile.empty,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ProfileDiscoveryInsightCard()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(ProfileCopy.discoveryInsightTitle), findsOneWidget);
    expect(find.text(ProfileCopy.storyEmpty), findsOneWidget);
    expect(find.text('Değişim'), findsNothing);
  });

  testWidgets('card lists real recurring theme chips', (tester) async {
    final profile = PersonalDiscoveryProfile(
      lastUpdated: DateTime(2026, 8, 10),
      tarotCount: 2,
      coffeeCount: 1,
      crossInsights: [
        recurring('değişim'),
        recurring('iletişim'),
        recurring('karar verme'),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          personalDiscoveryProfileProvider.overrideWith((ref) async => profile),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ProfileDiscoveryInsightCard()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Değişim'), findsOneWidget);
    expect(find.text('İletişim'), findsOneWidget);
    expect(find.text('Karar Verme'), findsOneWidget);
    expect(find.text(ProfileCopy.storyEmpty), findsNothing);
  });
}
