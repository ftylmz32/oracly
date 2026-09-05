/// Structured proxy payloads — no giant UI prompt blobs.
library;

import '../../services/prompt_sanitizer.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/personality/or_response_depth.dart';
import '../contexts/reading_ai_context.dart';
import '../../../companion/services/or_operation_id.dart';
import '../../../gems/services/paid_ai_operation_id.dart';
import '../models/conversation_turn.dart';
import '../models/tarot_ai_analysis.dart';
import '../transport/ai_operation.dart';
import '../transport/ai_proxy_request.dart';
import '../transport/reading_context_json.dart';
import 'openai_paid_requests.dart';

abstract final class OpenAiServiceRequests {
  OpenAiServiceRequests._();

  static AiProxyRequest chat({
    required String model,
    required String userMessage,
    required List<String> priorUser,
    String? styleHint,
    String? personality,
    List<ConversationTurn> turns = const [],
    OrResponseDepth depth = OrResponseDepth.fallback,
    bool spoken = false,
  }) {
    final style = (styleHint ?? '').trim();
    final voice = (personality ?? '').trim();
    final encoded = [
      for (final turn in ConversationTurn.takeRecent(turns)) turn.toPayload(),
    ];
    final payload = <String, dynamic>{
      'userMessage': PromptSanitizer.sanitize(userMessage),
      if (encoded.isEmpty) 'priorUser': _prior(priorUser, max: 4),
      if (encoded.isNotEmpty) 'turns': encoded,
      if (voice.isNotEmpty) 'personality': voice,
      if (style.isNotEmpty) 'styleHint': PromptSanitizer.sanitize(style),
      'depth': depth.name,
      'spoken': spoken,
      ..._language,
    };
    return AiProxyRequest(
      operation: AiOperation.chat,
      model: model,
      payload: payload,
      idempotencyKey:
          OrOperationId.current ?? PaidAiOperationId.create('chat'),
    );
  }

  static AiProxyRequest oracle({
    required String model,
    required ReadingAiContext context,
    required String userMessage,
    required List<String> priorUser,
    List<String> observedThemes = const [],
    String? styleHint,
    String? personality,
    List<ConversationTurn> turns = const [],
    OrResponseDepth depth = OrResponseDepth.fallback,
    bool spoken = false,
  }) {
    final ctx = ReadingContextJson.toJson(context);
    final themes = [
      for (final theme in observedThemes)
        if (theme.trim().isNotEmpty) PromptSanitizer.sanitize(theme),
    ].take(4).toList();
    if (themes.isNotEmpty) ctx['observedThemes'] = themes;
    final style = (styleHint ?? '').trim();
    final voice = (personality ?? '').trim();
    final encoded = [
      for (final turn in ConversationTurn.takeRecent(turns)) turn.toPayload(),
    ];
    final payload = <String, dynamic>{
      'userMessage': PromptSanitizer.sanitize(userMessage),
      if (encoded.isEmpty) 'priorUser': _prior(priorUser, max: 8),
      if (encoded.isNotEmpty) 'turns': encoded,
      if (voice.isNotEmpty) 'personality': voice,
      if (style.isNotEmpty) 'styleHint': PromptSanitizer.sanitize(style),
      'depth': depth.name,
      'spoken': spoken,
      'context': ctx,
      ..._language,
    };
    return AiProxyRequest(
      operation: AiOperation.oracle,
      model: model,
      payload: payload,
      idempotencyKey:
          OrOperationId.current ?? PaidAiOperationId.create('oracle'),
    );
  }

  static AiProxyRequest tarot({
    required String model,
    required TarotAiRequestContext context,
  }) {
    final cards = [
      for (final card in context.cards.take(10))
        {
          'cardId': card.cardId,
          'cardName': PromptSanitizer.sanitize(card.cardName),
          'positionLabel': PromptSanitizer.sanitize(card.positionLabel),
          'positionKey': PromptSanitizer.sanitize(card.positionKey),
          'isReversed': card.isReversed,
          'meaning': PromptSanitizer.sanitize(card.meaning),
          'keywords': [
            for (final keyword in card.keywords.take(8))
              if (keyword.trim().isNotEmpty)
                PromptSanitizer.sanitize(keyword),
          ],
        },
    ];
    final continuity = context.continuity.toPayload();
    final payload = <String, dynamic>{
      'sessionId': PromptSanitizer.sanitize(context.sessionId),
      'spreadLabel': PromptSanitizer.sanitize(context.spreadLabel),
      if ((context.userQuestion ?? '').trim().isNotEmpty)
        'userQuestion': PromptSanitizer.sanitize(context.userQuestion!),
      if ((context.readingTheme ?? '').trim().isNotEmpty)
        'readingTheme': PromptSanitizer.sanitize(context.readingTheme!),
      'cards': cards,
      if (continuity.isNotEmpty) 'continuity': continuity,
      ..._language,
    };
    return AiProxyRequest(
      operation: AiOperation.tarotAnalysis,
      model: model,
      payload: payload,
      idempotencyKey:
          PaidAiOperationId.fromExisting('tarot', context.operationId),
    );
  }

  static AiProxyRequest dream({
    required String model,
    required DreamAiContext context,
  }) =>
      OpenAiPaidRequests.dream(model: model, context: context);

  static AiProxyRequest coffee({
    required String model,
    required List<int> imageBytes,
    required String mimeType,
  }) =>
      OpenAiPaidRequests.coffee(
        model: model,
        imageBytes: imageBytes,
        mimeType: mimeType,
      );

  static AiProxyRequest palm({
    required String model,
    required List<int> imageBytes,
    required String mimeType,
    required String hand,
  }) =>
      OpenAiPaidRequests.palm(
        model: model,
        imageBytes: imageBytes,
        mimeType: mimeType,
        hand: hand,
      );

  static Map<String, String> get _language => {
        'language': OraclyL10n.code,
      };

  static List<String> _prior(List<String> prior, {int max = 6}) {
    return prior.reversed
        .take(max)
        .toList()
        .reversed
        .map(PromptSanitizer.sanitize)
        .where((e) => e.isNotEmpty)
        .toList();
  }
}
