/// Home hero — living returning greeting wired without changing CTA priority.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/copy/first_session_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_history_repository.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/core/experience/domain/models/experience_context.dart';
import 'package:oracly_new/core/experience/domain/models/greeting_context.dart';
import 'package:oracly_new/core/experience/domain/models/journey_context.dart';
import 'package:oracly_new/core/experience/domain/models/recommendation_context.dart';
import 'package:oracly_new/core/experience/domain/models/reflection_context.dart';
import 'package:oracly_new/core/first_session/first_session_intent.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/personality/living_greeting_copy.dart';
import 'package:oracly_new/core/universe/oracly_universe_state.dart';
import 'package:oracly_new/features/companion/services/first_reading_or_deepen.dart';
import 'package:oracly_new/features/home/master/home_master_hero.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  final clock = DateTime(2026, 8, 29, 12);

  ExperienceContext returningExperience() => ExperienceContext(
    generatedAt: clock,
    schemaVersion: ExperienceContext.currentSchemaVersion,
    greeting: const GreetingContext(
      tone: GreetingTone.returning,
      styleKey: 'greeting_returning_afternoon',
      personalizeWithJourney: true,
    ),
    reflection: const ReflectionContext(
      style: ReflectionStyle.gentle,
      surfacePersonalInsights: false,
      preferShortForm: false,
    ),
    journey: const JourneyContext(
      hasJourneyMemory: true,
      highlightTodaysRitual: true,
      ritualCompletedToday: false,
      totalReadings: 2,
      hasRecurringPatterns: false,
    ),
    recommendations: const RecommendationContext(
      primaryHighlight: ExperienceHighlight.dailyRitual,
      secondaryHighlights: [],
      premium: PremiumRelevance(isRelevant: false),
      aiAvailable: true,
      featureFlags: {},
    ),
  );

  ExperienceContext morningExperience() => ExperienceContext(
    generatedAt: clock,
    schemaVersion: ExperienceContext.currentSchemaVersion,
    greeting: const GreetingContext(
      tone: GreetingTone.afternoon,
      styleKey: 'greeting_afternoon',
      personalizeWithJourney: true,
    ),
    reflection: const ReflectionContext(
      style: ReflectionStyle.gentle,
      surfacePersonalInsights: false,
      preferShortForm: false,
    ),
    journey: const JourneyContext(
      hasJourneyMemory: true,
      highlightTodaysRitual: false,
      ritualCompletedToday: true,
      totalReadings: 2,
      hasRecurringPatterns: false,
    ),
    recommendations: const RecommendationContext(
      primaryHighlight: ExperienceHighlight.none,
      secondaryHighlights: [],
      premium: PremiumRelevance(isRelevant: false),
      aiAvailable: true,
      featureFlags: {},
    ),
  );

  ReadingModel reading({required String id, String cardName = 'The Star'}) {
    return ReadingModel(
      id: id,
      cardId: 17,
      cardName: cardName,
      cardImageAsset: 'star.png',
      spreadType: 'Tek Kart',
      aiSummary: 'Ozet',
      createdAt: clock.subtract(const Duration(hours: 2)),
      sessionId: id,
      cards: [
        ReadingCardSnapshot(
          cardId: 17,
          cardName: cardName,
          cardImageAsset: 'star.png',
          positionIndex: 0,
        ),
      ],
    );
  }

  Future<void> markConsumed(LocalStorage storage, String sessionId) async {
    await FirstReadingOrDeepen.markEligible(storage, sessionId);
    await storage.setBool(FirstReadingOrDeepen.consumedKey, true);
  }

  testWidgets('first-session pending ignores returning living copy', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await FirstSessionIntent.requestFirstReading(storage);
    await markConsumed(storage, 'session_first');
    await MockHistoryRepository(
      storage,
    ).saveReading(reading(id: 'session_first'));

    final living = returningExperience();
    final returningInvite = LivingGreetingCopy.subtitle(
      experience: living,
      universe: OraclyUniverseState.current(clock),
      settings: const PersonalizationSettings(),
      asOf: clock,
    );

    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        overrides: [
          firstReadingPendingProvider.overrideWith((ref) => true),
          livingExperienceProvider.overrideWith((ref) async => living),
        ],
        child: const MaterialApp(home: Scaffold(body: HomeMasterHero())),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(FirstSessionCopy.homeCta), findsOneWidget);
    expect(find.text(FirstSessionCopy.homeSubtitleNew), findsOneWidget);
    expect(find.text(returningInvite), findsNothing);
    expect(find.text(FirstSessionCopy.continuityCta), findsNothing);
  });

  testWidgets('continuity keeps CTA and card invite when returning', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await markConsumed(storage, 'session_first');
    await MockHistoryRepository(
      storage,
    ).saveReading(reading(id: 'session_first', cardName: 'The Star'));

    final living = returningExperience();
    final softHello = LivingGreetingCopy.greetingLabel(
      experience: living,
      asOf: clock,
    );
    final returningInvite = LivingGreetingCopy.subtitle(
      experience: living,
      universe: OraclyUniverseState.current(clock),
      settings: const PersonalizationSettings(),
      asOf: clock,
    );

    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        overrides: [
          firstReadingPendingProvider.overrideWith((ref) => false),
          livingExperienceProvider.overrideWith((ref) async => living),
        ],
        child: const MaterialApp(home: Scaffold(body: HomeMasterHero())),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(FirstSessionCopy.continuityCta), findsOneWidget);
    expect(
      find.text(FirstSessionCopy.continuityInvite('The Star')),
      findsOneWidget,
    );
    expect(find.text(softHello), findsOneWidget);
    expect(find.text(returningInvite), findsNothing);
    expect(find.text(FirstSessionCopy.homeCta), findsNothing);
  });

  testWidgets('default hero uses LivingGreetingCopy when returning', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();

    final living = returningExperience();
    final expectedHello = LivingGreetingCopy.greetingLabel(
      experience: living,
      asOf: clock,
    );
    final expectedInvite = LivingGreetingCopy.subtitle(
      experience: living,
      universe: OraclyUniverseState.current(clock),
      settings: const PersonalizationSettings(),
      asOf: clock,
    );

    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        overrides: [
          firstReadingPendingProvider.overrideWith((ref) => false),
          livingExperienceProvider.overrideWith((ref) async => living),
        ],
        child: const MaterialApp(home: Scaffold(body: HomeMasterHero())),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(expectedHello), findsOneWidget);
    expect(find.text(expectedInvite), findsOneWidget);
    expect(find.text(FirstSessionCopy.continuityCta), findsNothing);
    expect(find.text(FirstSessionCopy.homeCta), findsNothing);
  });

  testWidgets('non-returning living experience keeps default hero plate', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();

    final living = morningExperience();
    final returningInvite = LivingGreetingCopy.subtitle(
      experience: returningExperience(),
      universe: OraclyUniverseState.current(clock),
      settings: const PersonalizationSettings(),
      asOf: clock,
    );

    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        overrides: [
          firstReadingPendingProvider.overrideWith((ref) => false),
          livingExperienceProvider.overrideWith((ref) async => living),
        ],
        child: const MaterialApp(home: Scaffold(body: HomeMasterHero())),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Merhaba,'), findsOneWidget);
    expect(find.text(returningInvite), findsNothing);
    expect(find.text(FirstSessionCopy.continuityCta), findsNothing);
  });

  testWidgets('unavailable living experience keeps default hero plate', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();

    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        overrides: [
          firstReadingPendingProvider.overrideWith((ref) => false),
          livingExperienceProvider.overrideWith(
            (ref) => Future<ExperienceContext>.error(StateError('offline')),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: HomeMasterHero())),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Merhaba,'), findsOneWidget);
    expect(find.byType(HomeMasterHero), findsOneWidget);
  });
}
