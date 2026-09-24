/// Live AI via [AiTransport] — features never see OpenAI or proxy details.
library;

import '../ai_outcome.dart';
import '../ai_request_abuse_policy.dart';
import '../ai_request_fingerprint.dart';
import '../ai_request_guard.dart';
import '../ai_runtime_config.dart';
import '../contexts/reading_ai_context.dart';
import '../models/chat_ai_reply.dart';
import '../models/coffee_ai_analysis.dart';
import '../models/conversation_turn.dart';
import '../../../../core/personality/or_response_depth.dart';
import '../models/dream_ai_analysis.dart';
import '../models/palm_ai_analysis.dart';
import '../oracly_ai_service.dart';
import '../oracly_narrative_tarot_ai_service.dart';
import '../transport/ai_transport.dart';
import 'openai_image_analysis.dart';
import 'openai_paid_requests.dart';
import 'openai_service_requests.dart';
import 'openai_service_results.dart';
import '../../../companion/services/or_operation_id.dart';

class OpenAiOraclyAiService
    implements
        OraclyAiService,
        OraclyStagedImageAiService,
        OraclyEvidenceMemoryAiService,
        OraclyNarrativeTarotAiService {
  OpenAiOraclyAiService({
    required this._config,
    required this._transport,
    AiRequestGuard? guard,
  }) : _guard = guard ?? AiRequestGuard.shared;

  final AiRuntimeConfig _config;
  final AiTransport _transport;
  final AiRequestGuard _guard;
  late final OpenAiImageAnalysis _images = OpenAiImageAnalysis(
    config: _config,
    transport: _transport,
    guard: _guard,
  );

  @override
  bool get isConfigured => _config.isConfigured;

  @override
  bool get visionAvailable => _config.visionAvailable;

  @override
  bool get allowsLocalFallback => _config.allowsLocalFallback;

  @override
  Future<AiOutcome<ChatAiReply>> chat({
    required String userMessage,
    List<String> priorUser = const [],
    String? styleHint,
    String? personality,
    List<ConversationTurn> turns = const [],
    OrResponseDepth depth = OrResponseDepth.fallback,
    bool spoken = false,
  }) {
    return _guard.runOutcome(
      OrOperationId.current ?? 'chat',
      kind: AiRequestKind.chat,
      fingerprint:
          OrOperationId.current ??
          AiRequestFingerprint.text('chat', userMessage),
      () async {
        return OpenAiServiceResults.chat(
          await _transport.execute(
            OpenAiServiceRequests.chat(
              model: _config.model,
              userMessage: userMessage,
              priorUser: priorUser,
              styleHint: styleHint,
              personality: personality,
              turns: turns,
              depth: depth,
              spoken: spoken,
            ),
          ),
          _config.model,
        );
      },
    );
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
  }) {
    return _guard.runOutcome(
      OrOperationId.current ?? 'oracle:${context.kindId}',
      kind: AiRequestKind.oracle,
      fingerprint:
          OrOperationId.current ??
          AiRequestFingerprint.text('oracle:${context.kindId}', userMessage),
      () async {
        return OpenAiServiceResults.chat(
          await _transport.execute(
            OpenAiServiceRequests.oracle(
              model: _config.model,
              context: context,
              userMessage: userMessage,
              priorUser: priorUser,
              observedThemes: observedThemes,
              styleHint: styleHint,
              personality: personality,
              turns: turns,
              depth: depth,
              spoken: spoken,
            ),
          ),
          _config.model,
        );
      },
    );
  }

  @override
  Future<AiOutcome<ChatAiReply>> generateTarotReading({
    required List<Map<String, dynamic>> cards,
    required String spreadLabel,
    String? userQuestion,
    String? readingTheme,
    Map<String, dynamic>? journeyHints,
  }) {
    final cardsKey = cards
        .map((c) => '${c['name']}:${c['positionLabel']}:${c['reversed']}')
        .join(',');
    return _guard.runOutcome(
      'tarot:$cardsKey',
      kind: AiRequestKind.tarot,
      fingerprint: AiRequestFingerprint.text('tarot', cardsKey),
      () async {
        return OpenAiServiceResults.chat(
          await _transport.execute(
            OpenAiPaidRequests.tarotReading(
              cards: cards,
              spreadLabel: spreadLabel,
              userQuestion: userQuestion,
              readingTheme: readingTheme,
              journeyHints: journeyHints,
            ),
          ),
          _config.model,
        );
      },
    );
  }

  @override
  Future<AiOutcome<Map<String, dynamic>>> generateNarrativeTarotReading({
    required Map<String, dynamic> payload,
    required String fingerprint,
  }) {
    return _guard.runOutcome(
      'tarot-narrative:$fingerprint',
      kind: AiRequestKind.tarot,
      fingerprint: fingerprint,
      () async {
        return _transport.execute(
          OpenAiPaidRequests.tarotNarrative(
            payload: payload,
            fingerprint: fingerprint,
          ),
        );
      },
    );
  }

  @override
  Future<AiOutcome<DreamAiAnalysis>> analyzeDream(DreamAiContext context) {
    return _guard.runOutcome(
      'dream',
      kind: AiRequestKind.dream,
      fingerprint: AiRequestFingerprint.text(
        'dream',
        '${context.narrative}|${context.memorySummary ?? ''}',
      ),
      () async {
        return OpenAiServiceResults.dream(
          await _transport.execute(
            OpenAiPaidRequests.dream(model: _config.model, context: context),
          ),
        );
      },
    );
  }

  @override
  Future<AiOutcome<CoffeeAiAnalysis>> analyzeCoffee({
    required List<int> imageBytes,
    required String mimeType,
    Map<String, dynamic>? personalization,
  }) => _images.coffee(
    imageBytes: imageBytes,
    mimeType: mimeType,
    personalization: personalization,
  );

  @override
  Future<AiOutcome<PalmAiAnalysis>> analyzePalm({
    required List<int> imageBytes,
    required String mimeType,
    required String hand,
    Map<String, dynamic>? personalization,
  }) => _images.palm(
    imageBytes: imageBytes,
    mimeType: mimeType,
    hand: hand,
    personalization: personalization,
  );

  @override
  Future<AiOutcome<CoffeeAiAnalysis>> analyzeCoffeeStaged({
    required String operationId,
    required String mimeType,
    Map<String, dynamic>? personalization,
  }) => _images.coffeeStaged(
    operationId: operationId,
    mimeType: mimeType,
    personalization: personalization,
  );

  @override
  Future<AiOutcome<PalmAiAnalysis>> analyzePalmStaged({
    required String operationId,
    required String mimeType,
    required String hand,
    Map<String, dynamic>? personalization,
  }) => _images.palmStaged(
    operationId: operationId,
    mimeType: mimeType,
    hand: hand,
    personalization: personalization,
  );

  @override
  Future<AiOutcome<CoffeeAiAnalysis>> analyzeCoffeeWithEvidenceMemory({
    required List<int> imageBytes,
    required String mimeType,
    required Map<String, dynamic>? basePersonalization,
    required String? Function(List<String> themes) memorySummary,
  }) => _images.coffeeWithEvidenceMemory(
    imageBytes: imageBytes,
    mimeType: mimeType,
    basePersonalization: basePersonalization,
    memorySummary: memorySummary,
  );

  @override
  Future<AiOutcome<PalmAiAnalysis>> analyzePalmWithEvidenceMemory({
    required List<int> imageBytes,
    required String mimeType,
    required String hand,
    required Map<String, dynamic>? basePersonalization,
    required String? Function(List<String> themes) memorySummary,
  }) => _images.palmWithEvidenceMemory(
    imageBytes: imageBytes,
    mimeType: mimeType,
    hand: hand,
    basePersonalization: basePersonalization,
    memorySummary: memorySummary,
  );

  @override
  Future<AiOutcome<CoffeeAiAnalysis>> analyzeCoffeeStagedWithEvidenceMemory({
    required String operationId,
    required String mimeType,
    required Map<String, dynamic>? basePersonalization,
    required String? Function(List<String> themes) memorySummary,
  }) => _images.coffeeStagedWithEvidenceMemory(
    operationId: operationId,
    mimeType: mimeType,
    basePersonalization: basePersonalization,
    memorySummary: memorySummary,
  );

  @override
  Future<AiOutcome<PalmAiAnalysis>> analyzePalmStagedWithEvidenceMemory({
    required String operationId,
    required String mimeType,
    required String hand,
    required Map<String, dynamic>? basePersonalization,
    required String? Function(List<String> themes) memorySummary,
  }) => _images.palmStagedWithEvidenceMemory(
    operationId: operationId,
    mimeType: mimeType,
    hand: hand,
    basePersonalization: basePersonalization,
    memorySummary: memorySummary,
  );
}
