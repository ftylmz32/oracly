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
import '../models/tarot_ai_analysis.dart';
import '../oracly_ai_service.dart';
import '../transport/ai_transport.dart';
import 'openai_image_analysis.dart';
import 'openai_paid_requests.dart';
import 'openai_service_requests.dart';
import 'openai_service_results.dart';
import '../../../companion/services/or_operation_id.dart';

class OpenAiOraclyAiService implements OraclyAiService {
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
          OrOperationId.current ?? AiRequestFingerprint.text('chat', userMessage),
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
  Future<AiOutcome<DreamAiAnalysis>> analyzeDream(DreamAiContext context) {
    return _guard.runOutcome(
      'dream',
      kind: AiRequestKind.dream,
      fingerprint: AiRequestFingerprint.text('dream', context.narrative),
      () async {
        return OpenAiServiceResults.dream(
          await _transport.execute(
            OpenAiPaidRequests.dream(
              model: _config.model,
              context: context,
            ),
          ),
        );
      },
    );
  }

  @override
  Future<AiOutcome<TarotAiAnalysis>> analyzeTarot(
    TarotAiRequestContext context,
  ) {
    final cardKey = context.cards
        .map((card) => '${card.cardId}:${card.isReversed ? 1 : 0}:${card.positionKey}')
        .join('|');
    final fingerprint = AiRequestFingerprint.text(
      'tarot',
      '${context.sessionId}|$cardKey|${context.continuity.priorReadingCount}',
    );
    return _guard.runOutcome(
      'tarot:${context.sessionId}',
      kind: AiRequestKind.tarot,
      fingerprint: fingerprint,
      () async {
        return OpenAiServiceResults.tarot(
          await _transport.execute(
            OpenAiServiceRequests.tarot(
              model: _config.model,
              context: context,
            ),
          ),
        );
      },
    );
  }

  @override
  Future<AiOutcome<CoffeeAiAnalysis>> analyzeCoffee({
    required List<int> imageBytes,
    required String mimeType,
  }) =>
      _images.coffee(imageBytes: imageBytes, mimeType: mimeType);

  @override
  Future<AiOutcome<PalmAiAnalysis>> analyzePalm({
    required List<int> imageBytes,
    required String mimeType,
    required String hand,
  }) =>
      _images.palm(
        imageBytes: imageBytes,
        mimeType: mimeType,
        hand: hand,
      );
}
