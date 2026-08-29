/// First continuity Home recall — evidence, priority, fail-closed.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/copy/first_session_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_ai_conversation_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_history_repository.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/core/first_session/first_session_intent.dart';
import 'package:oracly_new/core/intelligence/data/intelligence_index_store.dart';
import 'package:oracly_new/core/intelligence/data/local_intelligence_repository.dart';
import 'package:oracly_new/core/intelligence/data/ritual_history_reader.dart';
import 'package:oracly_new/core/intelligence/services/intelligence_layer_service.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/domain/models/ai_message.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context.dart';
import 'package:oracly_new/features/companion/controllers/companion_controller.dart';
import 'package:oracly_new/features/companion/controllers/companion_output_controller.dart';
import 'package:oracly_new/features/companion/models/conversation.dart';
import 'package:oracly_new/features/companion/models/or_chat_output_mode.dart';
import 'package:oracly_new/features/companion/services/companion_experience_service.dart';
import 'package:oracly_new/features/companion/services/first_reading_or_deepen.dart';
import 'package:oracly_new/features/home/master/home_master_hero.dart';
import 'package:oracly_new/features/home/reference/home_reference_hero.dart';
import 'package:oracly_new/features/home/services/first_continuity_home.dart';
import 'package:oracly_new/features/premium/models/premium_entitlement_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  final clock = DateTime(2026, 8, 29, 12);

  ReadingModel reading({
    required String id,
    String cardName = 'The Star',
    String? intention,
    DateTime? createdAt,
    String? sessionId,
  }) {
    final display = cardName.contains(' · ')
        ? cardName.split(' · ').last
        : cardName;
    return ReadingModel(
      id: id,
      cardId: 17,
      cardName: cardName,
      cardImageAsset: 'star.png',
      spreadType: 'Tek Kart',
      aiSummary: 'Umut ve yenilenme. Gizli ozet asla Homeda olmamali.',
      createdAt: createdAt ?? DateTime.now().subtract(const Duration(hours: 2)),
      sessionId: sessionId ?? id,
      intention: intention,
      cards: [
        ReadingCardSnapshot(
          cardId: 17,
          cardName: display,
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

  group('resolve', () {
    test('pending deepen does not unlock continuity', () async {
      final storage = LocalStorage.ephemeral();
      await FirstReadingOrDeepen.markEligible(storage, 'session_first');
      expect(FirstReadingOrDeepen.isConsumed(storage), isFalse);

      final state = FirstContinuityHome.resolve(
        storage: storage,
        history: [
          reading(
            id: 'session_first',
            createdAt: clock.subtract(const Duration(hours: 2)),
          ),
        ],
        now: clock,
      );
      expect(state, isNull);
    });

    test('consumed + matching reading shows continuity', () async {
      final storage = LocalStorage.ephemeral();
      await markConsumed(storage, 'session_first');

      final state = FirstContinuityHome.resolve(
        storage: storage,
        history: [
          reading(
            id: 'session_first',
            cardName: 'The Star',
            createdAt: clock.subtract(const Duration(hours: 2)),
          ),
        ],
        now: clock,
      );
      expect(state, isNotNull);
      expect(state!.sessionId, 'session_first');
      expect(state.cardName, 'The Star');
    });

    test('exact session id must match — later reading ignored', () async {
      final storage = LocalStorage.ephemeral();
      await markConsumed(storage, 'session_first');

      final state = FirstContinuityHome.resolve(
        storage: storage,
        history: [
          reading(
            id: 'session_later',
            cardName: 'The Moon',
            createdAt: clock.subtract(const Duration(minutes: 5)),
          ),
          reading(
            id: 'session_first',
            cardName: 'The Star',
            createdAt: clock.subtract(const Duration(hours: 3)),
          ),
        ],
        now: clock,
      );
      expect(state!.cardName, 'The Star');
      expect(state.sessionId, 'session_first');
    });

    test('missing matching reading fails closed', () async {
      final storage = LocalStorage.ephemeral();
      await markConsumed(storage, 'session_first');

      final state = FirstContinuityHome.resolve(
        storage: storage,
        history: [
          reading(
            id: 'session_other',
            cardName: 'The Moon',
            createdAt: clock.subtract(const Duration(hours: 1)),
          ),
        ],
        now: clock,
      );
      expect(state, isNull);
    });

    test('stale journey outside window returns null', () async {
      final storage = LocalStorage.ephemeral();
      await markConsumed(storage, 'session_first');

      final state = FirstContinuityHome.resolve(
        storage: storage,
        history: [
          reading(
            id: 'session_first',
            createdAt: clock.subtract(const Duration(hours: 49)),
          ),
        ],
        now: clock,
      );
      expect(state, isNull);
    });

    test('safe card name never includes raw intention', () async {
      final storage = LocalStorage.ephemeral();
      await markConsumed(storage, 'session_first');
      const secret = 'Asik oldugum kisi beni seviyor mu?';

      final state = FirstContinuityHome.resolve(
        storage: storage,
        history: [
          reading(
            id: 'session_first',
            cardName: 'The Star',
            intention: secret,
            createdAt: clock.subtract(const Duration(hours: 1)),
          ),
        ],
        now: clock,
      );
      expect(state!.cardName, 'The Star');
      expect(state.cardName, isNot(contains(secret)));
      final invite = FirstSessionCopy.continuityInvite(state.cardName);
      expect(invite, isNot(contains(secret)));
      expect(invite, contains('The Star'));
    });
  });

  group('HomeMasterHero priority', () {
    testWidgets('pending first reading wins over continuity', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();
      await FirstSessionIntent.requestFirstReading(storage);
      await markConsumed(storage, 'session_first');
      await MockHistoryRepository(
        storage,
      ).saveReading(reading(id: 'session_first'));

      await tester.pumpWidget(
        buildProviderScopeHarness(
          storage: storage,
          overrides: [firstReadingPendingProvider.overrideWith((ref) => true)],
          child: const MaterialApp(home: Scaffold(body: HomeMasterHero())),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      expect(find.text(FirstSessionCopy.homeCta), findsOneWidget);
      expect(find.text(FirstSessionCopy.continuityCta), findsNothing);
      expect(find.text(FirstSessionCopy.homeSubtitleNew), findsOneWidget);
    });

    testWidgets('consumed deepen shows continuity CTA', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();
      await markConsumed(storage, 'session_first');
      await MockHistoryRepository(
        storage,
      ).saveReading(reading(id: 'session_first', cardName: 'The Star'));

      await tester.pumpWidget(
        buildProviderScopeHarness(
          storage: storage,
          overrides: [firstReadingPendingProvider.overrideWith((ref) => false)],
          child: const MaterialApp(home: Scaffold(body: HomeMasterHero())),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      expect(find.text(FirstSessionCopy.continuityCta), findsOneWidget);
      expect(find.text(FirstSessionCopy.homeCta), findsNothing);
      expect(
        find.text(FirstSessionCopy.continuityInvite('The Star')),
        findsOneWidget,
      );
      expect(find.byType(HomeReferenceHero), findsOneWidget);
    });

    testWidgets('unconsumed deepen keeps normal hero', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();
      await FirstReadingOrDeepen.markEligible(storage, 'session_first');
      await MockHistoryRepository(
        storage,
      ).saveReading(reading(id: 'session_first'));

      await tester.pumpWidget(
        buildProviderScopeHarness(
          storage: storage,
          overrides: [firstReadingPendingProvider.overrideWith((ref) => false)],
          child: const MaterialApp(home: Scaffold(body: HomeMasterHero())),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      expect(find.text('Merhaba,'), findsOneWidget);
      expect(find.text(FirstSessionCopy.continuityCta), findsNothing);
    });

    testWidgets('continuity CTA does not reset free deepen', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();
      await markConsumed(storage, 'session_first');
      var openedChat = false;

      await tester.pumpWidget(
        buildProviderScopeHarness(
          storage: storage,
          overrides: [firstReadingPendingProvider.overrideWith((ref) => false)],
          child: MaterialApp(
            home: Scaffold(
              body: HomeReferenceHero(
                hello: 'Merhaba, Fatih',
                invite: FirstSessionCopy.continuityInvite('The Star'),
                ctaLabel: FirstSessionCopy.continuityCta,
                onCta: () => openedChat = true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text(FirstSessionCopy.continuityCta));
      await tester.pump();

      expect(openedChat, isTrue);
      expect(FirstReadingOrDeepen.isConsumed(storage), isTrue);
      expect(
        FirstReadingOrDeepen.allows(
          storage,
          const OracleReadingContext(
            sessionId: 'session_first',
            spreadLabel: 'Tek Kart',
            deckId: 'classic',
            deckName: 'Classic',
            readingTitle: 'The Star',
            cardsSummary: 'The Star',
            interpretationSummary: 'Ozet',
            kind: OracleReadingKind.tarot,
            sourceLabel: 'Tarot',
          ),
        ),
        isFalse,
      );
    });
  });

  group('OR honesty after consumption', () {
    test('conversation reply remains; free compose stays gated', () async {
      final storage = LocalStorage.ephemeral();
      await markConsumed(storage, 'session_first');

      final output = CompanionOutputController(
        persistMode: (_) async {},
        readMode: () => OrChatOutputMode.text,
      );
      final controller = CompanionController(
        _UnusedExperience(),
        output,
        storage: storage,
      );
      final seed = DateTime(2026, 8, 29);
      const reply = 'Ilk derinlestirme yaniti.';
      controller.seedSessionForTest(
        conversation: Conversation(
          id: 'c1',
          title: 'OR',
          topic: ConversationTopic.general,
          messages: [
            AIMessage(
              id: 'a1',
              role: AIMessageRole.assistant,
              content: reply,
              createdAt: seed,
            ),
          ],
          createdAt: seed,
          updatedAt: seed,
        ),
        readingContext: const OracleReadingContext(
          sessionId: 'session_first',
          spreadLabel: 'Tek Kart',
          deckId: 'd',
          deckName: 'D',
          readingTitle: 'The Star',
          cardsSummary: 'The Star',
          interpretationSummary: 'Ozet',
          kind: OracleReadingKind.tarot,
          sourceLabel: 'Tarot',
        ),
      );

      expect(
        controller.state.conversation!.messages.any((m) => m.content == reply),
        isTrue,
      );
      expect(
        FirstReadingOrDeepen.allows(storage, controller.readingContext),
        isFalse,
      );
      expect(PremiumEntitlementState.active.allowsPremiumFeatures, isTrue);
      controller.dispose();
    });
  });
}

class _UnusedExperience extends CompanionExperienceService {
  _UnusedExperience()
    : super(
        conversationRepository: LocalAiConversationRepository(
          LocalStorage.ephemeral(),
        ),
        intelligence: IntelligenceLayerService(
          LocalIntelligenceRepository(
            history: MockHistoryRepository(LocalStorage.ephemeral()),
            conversations: LocalAiConversationRepository(
              LocalStorage.ephemeral(),
            ),
            ritualHistory: RitualHistoryReader(LocalStorage.ephemeral()),
            indexStore: IntelligenceIndexStore(LocalStorage.ephemeral()),
          ),
        ),
      );
}
