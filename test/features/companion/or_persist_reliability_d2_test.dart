/// D2 — OR generation vs local persistence trust boundary.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_ai_conversation_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_history_repository.dart';
import 'package:oracly_new/core/domain/models/conversation_record.dart';
import 'package:oracly_new/core/domain/repositories/ai_conversation_repository.dart';
import 'package:oracly_new/core/intelligence/data/intelligence_index_store.dart';
import 'package:oracly_new/core/intelligence/data/local_intelligence_repository.dart';
import 'package:oracly_new/core/intelligence/data/ritual_history_reader.dart';
import 'package:oracly_new/core/intelligence/services/intelligence_layer_service.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/personality/or_response_depth.dart';
import 'package:oracly_new/core/theme/app_theme.dart';
import 'package:oracly_new/features/ai/domain/models/ai_message.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/ai/production/ai_request_exception.dart';
import 'package:oracly_new/features/ai/production/contexts/reading_ai_context.dart';
import 'package:oracly_new/features/ai/production/models/chat_ai_reply.dart';
import 'package:oracly_new/features/ai/production/models/coffee_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/models/conversation_turn.dart';
import 'package:oracly_new/features/ai/production/models/dream_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/models/palm_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/oracly_ai_service.dart';
import 'package:oracly_new/features/companion/controllers/companion_controller.dart';
import 'package:oracly_new/features/companion/controllers/companion_output_controller.dart';
import 'package:oracly_new/features/companion/copy/companion_copy.dart';
import 'package:oracly_new/features/companion/data/companion_record_mapper.dart';
import 'package:oracly_new/features/companion/models/companion_send_result.dart';
import 'package:oracly_new/features/companion/models/companion_state.dart';
import 'package:oracly_new/features/companion/models/conversation.dart';
import 'package:oracly_new/features/companion/models/insight_request.dart';
import 'package:oracly_new/features/companion/models/or_chat_output_mode.dart';
import 'package:oracly_new/features/companion/models/or_session_state.dart';
import 'package:oracly_new/features/companion/models/reflection_context.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_notice.dart';
import 'package:oracly_new/features/companion/services/companion_experience_service.dart';
import 'package:oracly_new/features/companion/services/or_session_resolver.dart';
import 'package:oracly_new/features/companion/services/or_operation_id.dart';
import 'package:oracly_new/features/premium/models/premium_entitlement_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => OraclyL10n.bind('en'));

  group('generation vs persistence', () {
    test(
      'fresh identical submissions receive distinct opaque operation IDs',
      () async {
        final ai = _CountingAi();
        final repo = _CountingRepo();
        var sequence = 0;
        final controller = _controller(
          ai: ai,
          repo: repo,
          operationIdFactory: (feature) => 'or-$feature-${++sequence}',
        );
        await controller.send('same words');
        await controller.send('same words');
        expect(ai.operationIds, ['or-chat-1', 'or-chat-2']);
        final users = controller.state.conversation!.messages.where(
          (m) => m.isUser,
        );
        expect(
          users.map((m) => m.metadata[OrOperationId.stateKey]),
          everyElement(OrOperationId.completed),
        );
      },
    );

    test('failed retry reuses the persisted pending operation ID', () async {
      final ai = _CountingAi(failFirst: true);
      final repo = _CountingRepo();
      var sequence = 0;
      final controller = _controller(
        ai: ai,
        repo: repo,
        operationIdFactory: (feature) => 'or-$feature-${++sequence}',
      );
      await controller.send('retry me');
      expect(
        controller.state.conversation!.lastMessage!.metadata[OrOperationId
            .stateKey],
        OrOperationId.pending,
      );
      await controller.retryLast();
      expect(ai.operationIds, ['or-chat-1', 'or-chat-1']);
      expect(
        controller.state.conversation!.messages.where((m) => m.isUser),
        hasLength(1),
      );
    });

    test(
      'retry after restart restores and reuses pending operation ID',
      () async {
        final ai = _CountingAi(failFirst: true);
        final repo = _CountingRepo();
        final first = _controller(
          ai: ai,
          repo: repo,
          operationIdFactory: (_) => 'or-chat-persisted',
        );
        await first.send('survive restart');

        final restored = _unseededController(
          ai: ai,
          repo: repo,
          operationIdFactory: (_) => 'must-not-be-used',
        );
        await restored.initialize();
        expect(restored.state.lastFailedText, 'survive restart');
        await restored.retryLast();
        expect(ai.operationIds, ['or-chat-persisted', 'or-chat-persisted']);
      },
    );

    test('double tap allocates one ID and starts one request', () async {
      final ai = _CountingAi(delay: const Duration(milliseconds: 80));
      final repo = _CountingRepo();
      var allocations = 0;
      final controller = _controller(
        ai: ai,
        repo: repo,
        operationIdFactory: (feature) => 'or-$feature-${++allocations}',
      );
      await Future.wait([controller.send('once'), controller.send('once')]);
      expect(allocations, 1);
      expect(ai.chatCalls, 1);
    });

    test(
      'abandonment makes an identical new submission use a fresh ID',
      () async {
        final ai = _CountingAi(failFirst: true);
        final repo = _CountingRepo();
        var sequence = 0;
        final controller = _controller(
          ai: ai,
          repo: repo,
          operationIdFactory: (feature) => 'or-$feature-${++sequence}',
        );
        await controller.send('again');
        await controller.abandonPendingOperation();
        await controller.send('again');
        expect(ai.operationIds, ['or-chat-1', 'or-chat-2']);
        final users = controller.state.conversation!.messages
            .where((m) => m.isUser)
            .toList();
        expect(
          users.first.metadata[OrOperationId.stateKey],
          OrOperationId.abandoned,
        );
        expect(
          users.last.metadata[OrOperationId.stateKey],
          OrOperationId.completed,
        );
      },
    );

    test(
      'chat and oracle factories are namespaced without private input',
      () async {
        final ai = _CountingAi();
        final repo = _CountingRepo();
        final features = <String>[];
        final controller = _controller(
          ai: ai,
          repo: repo,
          operationIdFactory: (feature) {
            features.add(feature);
            return 'or-$feature-opaque';
          },
        );
        await controller.send('secret@example.com');
        controller.applyReadingHandoff(_readingContext());
        await controller.send('secret@example.com');
        expect(features, ['chat', 'oracle']);
        expect(ai.operationIds.toSet(), {'or-chat-opaque', 'or-oracle-opaque'});
        expect(ai.operationIds.join(), isNot(contains('secret')));
      },
    );

    test('operation metadata survives persistence mapping', () {
      final now = DateTime.now();
      final conversation = Conversation(
        id: 'pending',
        title: 'OR',
        topic: ConversationTopic.general,
        messages: [
          AIMessage(
            id: 'u1',
            role: AIMessageRole.user,
            content: 'private text',
            createdAt: now,
            metadata: const {
              OrOperationId.metadataKey: 'or-chat-opaque',
              OrOperationId.stateKey: OrOperationId.pending,
            },
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );
      final restored = CompanionRecordMapper.fromRecord(
        CompanionRecordMapper.toRecord(conversation),
      );
      expect(OrOperationId.pendingId(restored.lastMessage), 'or-chat-opaque');
      expect(
        OrOperationId.pendingId(restored.lastMessage),
        isNot(contains('private')),
      );
    });

    test('provider success + persistence success', () async {
      final ai = _CountingAi();
      final repo = _CountingRepo();
      final controller = _controller(ai: ai, repo: repo);
      await controller.send('hello');
      expect(ai.chatCalls, 1);
      expect(repo.saveCalls, greaterThanOrEqualTo(2));
      expect(controller.state.lastFailureKind, isNull);
      expect(
        controller.state.conversation!.messages.last.content,
        contains('live-reply'),
      );
      expect(controller.state.errorMessage, isNull);
    });

    test(
      'pending save failure blocks provider and retry reuses operation ID',
      () async {
        final ai = _CountingAi();
        final repo = _CountingRepo(failUser: true);
        final controller = _controller(
          ai: ai,
          repo: repo,
          operationIdFactory: (_) => 'or-chat-save-retry',
        );
        await controller.send('hello');
        expect(ai.chatCalls, 0);
        expect(controller.state.conversation!.lastMessage!.isUser, isTrue);
        expect(controller.state.errorMessage, CompanionCopy.saveFailed);
        repo.failUser = false;
        await controller.retryLast();
        expect(ai.chatCalls, 1);
        expect(ai.operationIds, ['or-chat-save-retry']);
      },
    );

    test(
      'provider success + assistant save failure keeps reply visible',
      () async {
        final ai = _CountingAi();
        final repo = _CountingRepo(failAssistant: true);
        final controller = _controller(ai: ai, repo: repo);
        await controller.send('hello');
        expect(ai.chatCalls, 1);
        expect(
          controller.state.lastFailureKind,
          AiFailureKind.localPersistence,
        );
        expect(controller.state.errorMessage, CompanionCopy.saveFailed);
        expect(
          controller.state.conversation!.messages.last.content,
          contains('live-reply'),
        );
        expect(controller.state.lastFailedText, isNull);
      },
    );

    test(
      'persistence retry does not call provider again and is idempotent',
      () async {
        final ai = _CountingAi();
        final repo = _CountingRepo(failAssistant: true);
        final controller = _controller(ai: ai, repo: repo);
        await controller.send('hello');
        expect(ai.chatCalls, 1);
        final assistantId = controller.state.conversation!.messages.last.id;
        final msgCount = controller.state.conversation!.messages.length;
        final savesBeforeRetry = repo.saveCalls;

        repo.failAssistant = false;
        await controller.retryLast();
        await controller.retryLast();
        await controller.retryPersist();

        expect(ai.chatCalls, 1, reason: 'zero extra provider calls');
        expect(controller.state.lastFailureKind, isNull);
        expect(controller.state.conversation!.messages.last.id, assistantId);
        expect(controller.state.conversation!.messages, hasLength(msgCount));
        expect(repo.saveCalls, greaterThan(savesBeforeRetry));

        final stored = await repo.getById(controller.state.conversation!.id);
        expect(stored, isNotNull);
        final mapped = CompanionRecordMapper.fromRecord(stored!);
        expect(mapped.messages.where((m) => m.id == assistantId), hasLength(1));
      },
    );

    test('repeated retry-save taps while busy do not duplicate', () async {
      final ai = _CountingAi();
      final repo = _CountingRepo(failAssistant: true, slowSave: true);
      final controller = _controller(ai: ai, repo: repo);
      await controller.send('hello');
      expect(ai.chatCalls, 1);
      repo.failAssistant = false;
      final a = controller.retryPersist();
      final b = controller.retryPersist();
      final c = controller.retryPersist();
      await Future.wait([a, b, c]);
      expect(ai.chatCalls, 1);
      expect(
        controller.state.conversation!.messages.where((m) => m.isAssistant),
        hasLength(2),
      );
    });

    test('genuine provider failure still uses provider retry', () async {
      final experience = _FailingProviderExperience();
      final controller = CompanionController(
        experience,
        CompanionOutputController(
          persistMode: (_) async {},
          readMode: () => OrChatOutputMode.text,
        ),
      );
      _seed(controller);
      await controller.send('hello');
      expect(controller.state.lastFailureKind, AiFailureKind.network);
      expect(controller.state.lastFailedText, 'hello');
      expect(experience.providerCalls, 1);
      await controller.retryLast();
      expect(experience.providerCalls, 2);
    });

    test('disposal during generation is safe', () async {
      final ai = _CountingAi(delay: const Duration(milliseconds: 120));
      final repo = _CountingRepo();
      final controller = _controller(ai: ai, repo: repo);
      final pending = controller.send('hello');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      controller.dispose();
      await pending;
      expect(ai.chatCalls, 1);
    });

    test('disposal during persistence retry is safe', () async {
      final ai = _CountingAi();
      final repo = _CountingRepo(failAssistant: true, slowSave: true);
      final controller = _controller(ai: ai, repo: repo);
      await controller.send('hello');
      repo.failAssistant = false;
      final pending = controller.retryPersist();
      controller.dispose();
      await pending;
      expect(ai.chatCalls, 1);
    });
  });

  group('corrupt history', () {
    test('one corrupt row does not hide valid history', () async {
      SharedPreferences.setMockInitialValues({
        'ai_conversations': [
          'not-json',
          jsonEncode(
            ConversationRecord(
              id: 'good',
              title: 'OR',
              kind: 'general',
              messagesJson: [
                {
                  'id': 'm1',
                  'role': 'assistant',
                  'content': 'still here',
                  'createdAt': DateTime.now().toIso8601String(),
                },
              ],
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ).toJson(),
          ),
        ],
      });
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final repo = LocalAiConversationRepository(storage);
      final all = await repo.getAll();
      expect(all, hasLength(1));
      expect(all.single.id, 'good');
      expect(repo.lastQuarantinedRows, 1);
    });

    test('one corrupt message is skipped; valid messages remain', () {
      final record = ConversationRecord(
        id: 'c1',
        title: 'OR',
        kind: 'general',
        messagesJson: [
          {
            'id': 'ok',
            'role': 'user',
            'content': 'hi',
            'createdAt': DateTime.now().toIso8601String(),
          },
          {
            'id': 'bad',
            'role': 'not-a-role',
            'content': 'x',
            'createdAt': 'nope',
          },
          {
            'id': 'ok2',
            'role': 'assistant',
            'content': 'reply',
            'createdAt': DateTime.now().toIso8601String(),
          },
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final conversation = CompanionRecordMapper.fromRecord(record);
      expect(conversation.messages.map((m) => m.id), ['ok', 'ok2']);
    });
  });

  group('session presentation', () {
    test('local persistence maps to saveFailed with retry', () {
      final p = OrSessionResolver.resolve(
        entitlement: PremiumEntitlementState.active,
        link: CompanionLinkStatus.online,
        lastFailure: AiFailureKind.localPersistence,
        voiceUnavailable: false,
        chamberEmpty: false,
      );
      expect(p.state, OrSessionState.saveFailed);
      expect(p.canRetry, isTrue);
      expect(p.statusLine, CompanionCopy.saveFailed);
      expect(p.canCompose, isTrue);
    });
  });

  group('UI notice', () {
    testWidgets('save-failed notice keeps composer path', (tester) async {
      for (final size in const [Size(320, 568), Size(390, 844)]) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: MediaQuery(
              data: MediaQueryData(size: size, disableAnimations: true),
              child: Scaffold(
                body: CompanionReferenceNotice(
                  message: CompanionCopy.saveFailed,
                  onRetry: () {},
                  compact: true,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.text(CompanionCopy.saveFailed), findsOneWidget);
        expect(find.text(CompanionCopy.retry), findsOneWidget);
      }
      await tester.binding.setSurfaceSize(null);
    });
  });
}

CompanionController _controller({
  required _CountingAi ai,
  required _CountingRepo repo,
  String Function(String feature)? operationIdFactory,
}) {
  final intelligence = IntelligenceLayerService(
    LocalIntelligenceRepository(
      history: MockHistoryRepository(LocalStorage.ephemeral()),
      conversations: repo,
      ritualHistory: RitualHistoryReader(LocalStorage.ephemeral()),
      indexStore: IntelligenceIndexStore(LocalStorage.ephemeral()),
    ),
  );
  final experience = CompanionExperienceService(
    conversationRepository: repo,
    intelligence: intelligence,
    ai: ai,
  );
  final controller = CompanionController(
    experience,
    CompanionOutputController(
      persistMode: (_) async {},
      readMode: () => OrChatOutputMode.text,
    ),
    operationIdFactory: operationIdFactory,
  );
  _seed(controller);
  return controller;
}

CompanionController _unseededController({
  required _CountingAi ai,
  required _CountingRepo repo,
  String Function(String feature)? operationIdFactory,
}) {
  final intelligence = IntelligenceLayerService(
    LocalIntelligenceRepository(
      history: MockHistoryRepository(LocalStorage.ephemeral()),
      conversations: repo,
      ritualHistory: RitualHistoryReader(LocalStorage.ephemeral()),
      indexStore: IntelligenceIndexStore(LocalStorage.ephemeral()),
    ),
  );
  return CompanionController(
    _RestartExperience(
      conversationRepository: repo,
      intelligence: intelligence,
      ai: ai,
    ),
    CompanionOutputController(
      persistMode: (_) async {},
      readMode: () => OrChatOutputMode.text,
    ),
    operationIdFactory: operationIdFactory,
  );
}

class _RestartExperience extends CompanionExperienceService {
  // The repository is also retained by this test double for deterministic load.
  // ignore: use_super_parameters
  _RestartExperience({
    required AiConversationRepository conversationRepository,
    required IntelligenceLayerService intelligence,
    required OraclyAiService ai,
  }) : conversationRepository = conversationRepository,
       super(
         conversationRepository: conversationRepository,
         intelligence: intelligence,
         ai: ai,
       );

  final AiConversationRepository conversationRepository;

  @override
  Future<({Conversation conversation, ReflectionContext context})>
  loadOrCreateSession() async {
    final rows = await conversationRepository.getAll();
    return (
      conversation: CompanionRecordMapper.fromRecord(rows.single),
      context: const ReflectionContext(),
    );
  }
}

OracleReadingContext _readingContext() => OracleReadingContext(
  sessionId: 'reading-1',
  spreadLabel: 'Coffee',
  deckId: 'coffee',
  deckName: 'Coffee',
  readingTitle: 'Coffee',
  cardsSummary: 'Grounded symbols.',
  interpretationSummary: 'A grounded summary.',
  kind: OracleReadingKind.coffee,
);

void _seed(CompanionController controller) {
  final now = DateTime.now();
  controller.seedSessionForTest(
    conversation: Conversation(
      id: 'companion_primary',
      title: 'OR',
      topic: ConversationTopic.general,
      messages: [
        AIMessage(
          id: 'welcome',
          role: AIMessageRole.assistant,
          content: 'Welcome.',
          createdAt: now,
        ),
      ],
      createdAt: now,
      updatedAt: now,
    ),
  );
}

class _CountingAi implements OraclyAiService {
  _CountingAi({this.delay, this.failFirst = false});
  final Duration? delay;
  final bool failFirst;
  int chatCalls = 0;
  final List<String?> operationIds = [];

  @override
  bool get isConfigured => true;
  @override
  bool get allowsLocalFallback => false;
  @override
  bool get visionAvailable => false;

  @override
  Future<AiOutcome<ChatAiReply>> chat({
    required String userMessage,
    List<String> priorUser = const [],
    String? styleHint,
    String? personality,
    List<ConversationTurn> turns = const [],
    OrResponseDepth depth = OrResponseDepth.fallback,
    bool spoken = false,
  }) async {
    chatCalls++;
    operationIds.add(OrOperationId.current);
    if (delay != null) await Future<void>.delayed(delay!);
    if (failFirst && chatCalls == 1) {
      return AiOutcome.failure(AiFailure.network());
    }
    return AiOutcome.success(const ChatAiReply(text: 'live-reply body'));
  }

  @override
  Future<AiOutcome<ChatAiReply>> askOracle({
    required ReadingAiContext context,
    required String userMessage,
    List<String> priorUser = const [],
    List<String> observedThemes = const [],
    String? styleHint,
    String? personality,
    List<ConversationTurn> turns = const [],
    OrResponseDepth depth = OrResponseDepth.fallback,
    bool spoken = false,
  }) => chat(userMessage: userMessage);

  @override
  Future<AiOutcome<DreamAiAnalysis>> analyzeDream(DreamAiContext context) {
    throw UnsupportedError('dream');
  }

  @override
  Future<AiOutcome<CoffeeAiAnalysis>> analyzeCoffee({
    required List<int> imageBytes,
    required String mimeType,
  }) {
    throw UnsupportedError('coffee');
  }

  @override
  Future<AiOutcome<PalmAiAnalysis>> analyzePalm({
    required List<int> imageBytes,
    required String mimeType,
    required String hand,
  }) {
    throw UnsupportedError('palm');
  }
}

class _CountingRepo implements AiConversationRepository {
  _CountingRepo({
    this.failUser = false,
    this.failAssistant = false,
    this.slowSave = false,
  });

  bool failUser;
  bool failAssistant;
  bool slowSave;
  int saveCalls = 0;
  final Map<String, ConversationRecord> _rows = {};

  @override
  Future<void> save(ConversationRecord record) async {
    saveCalls++;
    if (slowSave) await Future<void>.delayed(const Duration(milliseconds: 80));
    final hasAssistant = record.messagesJson.any(
      (m) => m['role'] == 'assistant' && m['id'] != 'welcome',
    );
    final hasUser = record.messagesJson.any((m) => m['role'] == 'user');
    if (failUser && hasUser && !hasAssistant) {
      throw StateError('user_persist_failed');
    }
    if (failAssistant && hasAssistant) {
      throw StateError('assistant_persist_failed');
    }
    _rows[record.id] = record;
  }

  @override
  Future<void> delete(String id) async => _rows.remove(id);

  @override
  Future<List<ConversationRecord>> getAll() async => _rows.values.toList();

  @override
  Future<ConversationRecord?> getById(String id) async => _rows[id];

  @override
  Future<void> sync() async {}
}

class _FailingProviderExperience extends CompanionExperienceService {
  _FailingProviderExperience()
    : super(
        conversationRepository: _CountingRepo(),
        intelligence: IntelligenceLayerService(
          LocalIntelligenceRepository(
            history: MockHistoryRepository(LocalStorage.ephemeral()),
            conversations: _CountingRepo(),
            ritualHistory: RitualHistoryReader(LocalStorage.ephemeral()),
            indexStore: IntelligenceIndexStore(LocalStorage.ephemeral()),
          ),
        ),
      );

  int providerCalls = 0;

  @override
  Future<CompanionSendResult> send({
    required Conversation conversation,
    required ReflectionContext context,
    required InsightRequest request,
    readingContext,
  }) async {
    providerCalls++;
    throw AiRequestException(AiFailure.network());
  }
}
