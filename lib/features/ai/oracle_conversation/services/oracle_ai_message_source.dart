/// OR'a Sor reply source — live AI, or dev-only local responder.
library;

import '../../../../core/honesty/or_response_grounding.dart';
import '../../production/ai_failure.dart';
import '../../production/ai_request_exception.dart';
import '../../production/contexts/oracle_context_mapper.dart';
import '../../production/oracly_ai_service.dart';
import '../../services/conversation_response_guard.dart';
import '../models/oracle_reading_context.dart';
import 'oracle_conversation_responder.dart';

class OracleAiMessageSource {
  OracleAiMessageSource({
    this._ai,
    OracleConversationResponder? local,
    Future<List<String>> Function()? observedThemes,
    this._contextHintFor,
  })  : _local = local ?? const OracleConversationResponder(),
        _observedThemes = observedThemes ?? (() async => const <String>[]);

  final OraclyAiService? _ai;
  final OracleConversationResponder _local;
  final Future<List<String>> Function() _observedThemes;
  final Future<String?> Function(String userMessage)? _contextHintFor;

  bool get fromAi {
    final ai = _ai;
    return ai != null && ai.isConfigured;
  }

  bool get _useLocalFallback {
    final ai = _ai;
    return ai != null && !ai.isConfigured && ai.allowsLocalFallback;
  }

  Future<String> reply({
    required OracleReadingContext context,
    required String userMessage,
    List<String> priorUser = const [],
  }) async {
    if (_useLocalFallback) {
      return _local.respond(
        context: context,
        userMessage: userMessage,
        priorUser: priorUser,
      );
    }
    final ai = _ai;
    if (ai == null || !ai.isConfigured) {
      throw AiRequestException(AiFailure.noConfiguration());
    }

    final observedThemes = await _observedThemes();
    final contextHint = _tagObservation(
      await _contextHintFor?.call(userMessage),
    );
    final hasMemoryEvidence =
        observedThemes.isNotEmpty ||
        OrResponseGrounding.hasContextEvidence(contextHint);

    final outcome = await ai.askOracle(
      context: OracleContextMapper.fromOracle(context),
      userMessage: userMessage,
      priorUser: priorUser,
      observedThemes: observedThemes,
      styleHint: contextHint,
    );
    return outcome.when(
      success: (reply) => ConversationResponseGuard.polish(
        reply.text,
        userMessage: userMessage,
        hasMemoryEvidence: hasMemoryEvidence,
      ),
      error: (failure) => throw AiRequestException(failure),
    );
  }

  Stream<String> stream({
    required OracleReadingContext context,
    required String userMessage,
    List<String> priorUser = const [],
  }) async* {
    if (_useLocalFallback) {
      yield* _local.respondStream(
        context: context,
        userMessage: userMessage,
        priorUser: priorUser,
      );
      return;
    }
    final text = await reply(
      context: context,
      userMessage: userMessage,
      priorUser: priorUser,
    );
    final tokens = text.split(RegExp(r'(?<=\s)'));
    for (final token in tokens) {
      await Future<void>.delayed(const Duration(milliseconds: 32));
      yield token;
    }
  }

  static String? _tagObservation(String? raw) {
    final text = (raw ?? '').trim();
    if (text.isEmpty) return null;
    final capped = text.length <= 320 ? text : text.substring(0, 320).trim();
    return 'OBSERVATION: $capped';
  }
}
