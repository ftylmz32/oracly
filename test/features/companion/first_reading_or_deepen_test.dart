/// First-reading -> one free contextual OR deepen.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_ai_conversation_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_history_repository.dart';
import 'package:oracly_new/core/first_session/first_session_intent.dart';
import 'package:oracly_new/core/intelligence/data/intelligence_index_store.dart';
import 'package:oracly_new/core/intelligence/data/local_intelligence_repository.dart';
import 'package:oracly_new/core/intelligence/data/ritual_history_reader.dart';
import 'package:oracly_new/core/intelligence/services/intelligence_layer_service.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/domain/models/ai_message.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_request_exception.dart';
import 'package:oracly_new/features/companion/controllers/companion_controller.dart';
import 'package:oracly_new/features/companion/controllers/companion_output_controller.dart';
import 'package:oracly_new/features/companion/copy/companion_copy.dart';
import 'package:oracly_new/features/companion/models/companion_state.dart';
import 'package:oracly_new/features/companion/models/conversation.dart';
import 'package:oracly_new/features/companion/models/insight_request.dart';
import 'package:oracly_new/features/companion/models/or_chat_output_mode.dart';
import 'package:oracly_new/features/companion/models/or_session_state.dart';
import 'package:oracly_new/features/companion/models/reflection_context.dart';
import 'package:oracly_new/features/companion/services/companion_experience_service.dart';
import 'package:oracly_new/features/companion/services/companion_responder.dart';
import 'package:oracly_new/features/companion/services/first_reading_or_deepen.dart';
import 'package:oracly_new/features/companion/services/or_session_resolver.dart';
import 'package:oracly_new/features/premium/models/premium_entitlement_state.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/first_session/tarot_first_reading.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  OracleReadingContext tarot(String sessionId) => OracleReadingContext(
    sessionId: sessionId,
    spreadLabel: 'Tek Kart',
    deckId: 'classic',
    deckName: 'Classic',
    readingTitle: 'Kart',
    cardsSummary: 'Ay',
    interpretationSummary: 'Ozet.',
    kind: OracleReadingKind.tarot,
    sourceLabel: 'Tarot',
  );

  OracleReadingContext coffee(String sessionId) => OracleReadingContext(
    sessionId: sessionId,
    spreadLabel: 'Kahve',
    deckId: '',
    deckName: '',
    readingTitle: 'Fincan',
    cardsSummary: '',
    interpretationSummary: 'Ozet.',
    kind: OracleReadingKind.coffee,
    sourceLabel: 'Kahve',
  );

  group('eligibility store', () {
    test('first-session single-card session becomes eligible once', () async {
      final storage = LocalStorage.ephemeral();
      await FirstSessionIntent.requestFirstReading(storage);
      expect(TarotFirstReading.spread, TarotSpreadType.single);

      const sessionId = 'session_first';
      expect(FirstSessionIntent.isPending(storage), isTrue);
      await FirstReadingOrDeepen.markEligible(storage, sessionId);
      await FirstSessionIntent.consumePendingFirstReading(storage);

      expect(FirstReadingOrDeepen.eligibleSessionId(storage), sessionId);
      expect(FirstReadingOrDeepen.isConsumed(storage), isFalse);
      expect(FirstReadingOrDeepen.allows(storage, tarot(sessionId)), isTrue);
      expect(FirstSessionIntent.isPending(storage), isFalse);
    });

    test('later single-card session does not replace eligibility', () async {
      final storage = LocalStorage.ephemeral();
      await FirstReadingOrDeepen.markEligible(storage, 'session_first');
      await FirstReadingOrDeepen.markEligible(storage, 'session_later');
      expect(FirstReadingOrDeepen.eligibleSessionId(storage), 'session_first');
      expect(
        FirstReadingOrDeepen.allows(storage, tarot('session_later')),
        isFalse,
      );
    });

    test('without markEligible path stays empty', () async {
      final storage = LocalStorage.ephemeral();
      expect(FirstSessionIntent.isPending(storage), isFalse);
      expect(FirstReadingOrDeepen.eligibleSessionId(storage), isNull);
      expect(FirstReadingOrDeepen.allows(storage, tarot('any')), isFalse);
    });
  });

  group('access matching', () {
    test('matching Tarot context allows free compose', () async {
      final storage = LocalStorage.ephemeral();
      await FirstReadingOrDeepen.markEligible(storage, 's1');
      expect(FirstReadingOrDeepen.allows(storage, tarot('s1')), isTrue);

      final p = OrSessionResolver.resolve(
        entitlement: PremiumEntitlementState.inactive,
        link: CompanionLinkStatus.online,
        voiceUnavailable: false,
        contextualDeepenAllowed: true,
      );
      expect(p.state, OrSessionState.free);
      expect(p.canCompose, isTrue);
      expect(p.canUseMic, isFalse);
      expect(p.isGated, isFalse);
      expect(p.showPreview, isFalse);
      expect(p.statusLine, CompanionCopy.firstReadingDeepenHint);
    });

    test('generic OR without handoff stays Premium-gated', () async {
      final storage = LocalStorage.ephemeral();
      await FirstReadingOrDeepen.markEligible(storage, 's1');
      expect(FirstReadingOrDeepen.allows(storage, null), isFalse);

      final p = OrSessionResolver.resolve(
        entitlement: PremiumEntitlementState.inactive,
        link: CompanionLinkStatus.online,
        voiceUnavailable: false,
      );
      expect(p.canCompose, isFalse);
      expect(p.isGated, isTrue);
    });

    test('non-matching Tarot session stays gated', () async {
      final storage = LocalStorage.ephemeral();
      await FirstReadingOrDeepen.markEligible(storage, 's1');
      expect(FirstReadingOrDeepen.allows(storage, tarot('other')), isFalse);
    });

    test('non-Tarot handoff does not receive allowance', () async {
      final storage = LocalStorage.ephemeral();
      await FirstReadingOrDeepen.markEligible(storage, 's1');
      expect(FirstReadingOrDeepen.allows(storage, coffee('s1')), isFalse);
    });

    test('purchase pending never grants deepen compose', () {
      final p = OrSessionResolver.resolve(
        entitlement: PremiumEntitlementState.pending,
        link: CompanionLinkStatus.online,
        voiceUnavailable: false,
        contextualDeepenAllowed: true,
      );
      expect(p.state, OrSessionState.purchasePending);
      expect(p.canCompose, isFalse);
      expect(p.isGated, isTrue);
    });

    test('Premium users compose normally regardless of deepen', () {
      final p = OrSessionResolver.resolve(
        entitlement: PremiumEntitlementState.active,
        link: CompanionLinkStatus.online,
        voiceUnavailable: false,
        contextualDeepenAllowed: true,
      );
      expect(p.state, OrSessionState.success);
      expect(p.canCompose, isTrue);
      expect(p.canUseMic, isTrue);
    });
  });

  group('consumption lifecycle', () {
    test('opening does not consume', () async {
      final storage = LocalStorage.ephemeral();
      await FirstReadingOrDeepen.markEligible(storage, 's1');
      expect(FirstReadingOrDeepen.allows(storage, tarot('s1')), isTrue);
      expect(FirstReadingOrDeepen.isConsumed(storage), isFalse);
    });

    test('failed request preserves allowance', () async {
      final storage = LocalStorage.ephemeral();
      await FirstReadingOrDeepen.markEligible(storage, 's1');
      final controller = _controller(
        storage: storage,
        experience: _FailingExperience(),
        reading: tarot('s1'),
      );

      await controller.send('Derinlestir');

      expect(FirstReadingOrDeepen.isConsumed(storage), isFalse);
      expect(FirstReadingOrDeepen.allows(storage, tarot('s1')), isTrue);
      expect(controller.state.conversation!.messages.last.isUser, isTrue);
      controller.dispose();
    });

    test('successful assistant response consumes once', () async {
      final storage = LocalStorage.ephemeral();
      await FirstReadingOrDeepen.markEligible(storage, 's1');
      final experience = _ScriptedExperience(fromAi: true, body: 'Yansima.');
      final controller = _controller(
        storage: storage,
        experience: experience,
        reading: tarot('s1'),
      );

      await controller.send('Ne demek?');

      expect(experience.calls, 1);
      expect(experience.lastReading?.sessionId, 's1');
      expect(FirstReadingOrDeepen.isConsumed(storage), isTrue);
      expect(FirstReadingOrDeepen.allows(storage, tarot('s1')), isFalse);
      expect(
        controller.state.conversation!.messages.any(
          (m) => m.content == 'Yansima.',
        ),
        isTrue,
      );

      final after = OrSessionResolver.resolve(
        entitlement: PremiumEntitlementState.inactive,
        link: CompanionLinkStatus.online,
        voiceUnavailable: false,
        contextualDeepenAllowed: FirstReadingOrDeepen.allows(
          storage,
          tarot('s1'),
        ),
      );
      expect(after.canCompose, isFalse);
      expect(after.isGated, isTrue);
      controller.dispose();
    });

    test('local/non-AI reply does not consume allowance', () async {
      final storage = LocalStorage.ephemeral();
      await FirstReadingOrDeepen.markEligible(storage, 's1');
      final controller = _controller(
        storage: storage,
        experience: _ScriptedExperience(fromAi: false, body: 'Yerel.'),
        reading: tarot('s1'),
      );

      await controller.send('Ne demek?');

      expect(FirstReadingOrDeepen.isConsumed(storage), isFalse);
      expect(FirstReadingOrDeepen.allows(storage, tarot('s1')), isTrue);
      controller.dispose();
    });

    test('handoff context remains after consumption', () async {
      final storage = LocalStorage.ephemeral();
      await FirstReadingOrDeepen.markEligible(storage, 's1');
      final controller = _controller(
        storage: storage,
        experience: _ScriptedExperience(fromAi: true, body: 'Yanit.'),
        reading: tarot('s1'),
      );

      await controller.send('Devam');

      expect(controller.readingContext?.sessionId, 's1');
      expect(
        controller.state.conversation!.messages
            .where((m) => m.isAssistant)
            .map((m) => m.content)
            .contains('Yanit.'),
        isTrue,
      );
      controller.dispose();
    });
  });
}

CompanionController _controller({
  required LocalStorage storage,
  required CompanionExperienceService experience,
  required OracleReadingContext reading,
}) {
  final output = CompanionOutputController(
    persistMode: (_) async {},
    readMode: () => OrChatOutputMode.text,
  );
  final controller = CompanionController(experience, output, storage: storage);
  final now = DateTime.now();
  controller.seedSessionForTest(
    conversation: Conversation(
      id: 'c1',
      title: 'OR',
      topic: ConversationTopic.general,
      messages: [
        AIMessage(
          id: 'welcome',
          role: AIMessageRole.assistant,
          content: 'Hos geldin.',
          createdAt: now,
        ),
      ],
      createdAt: now,
      updatedAt: now,
    ),
    readingContext: reading,
  );
  return controller;
}

class _ScriptedExperience extends CompanionExperienceService {
  _ScriptedExperience({required this.fromAi, required this.body})
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

  final bool fromAi;
  final String body;
  int calls = 0;
  OracleReadingContext? lastReading;

  @override
  Future<({Conversation conversation, CompanionResponse response, bool fromAi})>
  send({
    required Conversation conversation,
    required ReflectionContext context,
    required InsightRequest request,
    OracleReadingContext? readingContext,
  }) async {
    calls++;
    lastReading = readingContext;
    final now = DateTime.now();
    final assistant = AIMessage(
      id: 'msg_a',
      role: AIMessageRole.assistant,
      content: body,
      createdAt: now,
    );
    return (
      conversation: conversation.copyWith(
        messages: [...conversation.messages, assistant],
        updatedAt: now,
      ),
      response: CompanionResponse(body: body),
      fromAi: fromAi,
    );
  }
}

class _FailingExperience extends CompanionExperienceService {
  _FailingExperience()
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

  @override
  Future<({Conversation conversation, CompanionResponse response, bool fromAi})>
  send({
    required Conversation conversation,
    required ReflectionContext context,
    required InsightRequest request,
    OracleReadingContext? readingContext,
  }) async {
    throw AiRequestException(AiFailure.network());
  }
}
