/// Canonical OR turn: safety → bridge (live) → local only if allowed.
///
/// Path: input → context → provider → parse → [OrResponseFinalize] → message.
/// Local catalogue never sets fromAi; live never invents provider success.
library;

import 'package:flutter/foundation.dart';

import '../../../core/safety/sensitive_topic_gate.dart';
import '../../ai/oracle_conversation/models/oracle_reading_context.dart';
import '../../ai/production/ai_failure.dart';
import '../../ai/production/ai_request_exception.dart';
import '../../ai/production/models/conversation_turn.dart';
import '../../../features/ai/domain/models/ai_message.dart';
import '../models/insight_request.dart';
import '../models/reflection_context.dart';
import 'companion_ai_bridge.dart';
import 'or_context_selection_engine.dart';
import 'companion_responder.dart';
import '../../../core/personality/or_response_depth.dart';
import 'companion_turn_window.dart';
import 'or_response_length_intelligence.dart';

class CompanionLiveReply {
  const CompanionLiveReply({
    required CompanionResponder responder,
    CompanionAiBridge? bridge,
    required Future<String?> Function(String userMessage) styleHint,
    required Future<String?> Function() personality,
    Future<({OrResponseDepth depth, bool spoken})> Function()? lengthPrefs,
    String? Function()? memoryPromptHint,
  }) : this._(
         bridge,
         styleHint,
         personality,
         lengthPrefs,
         memoryPromptHint,
       );

  const CompanionLiveReply._(
    this._bridge,
    this._styleHint,
    this._personality,
    this._lengthPrefs,
    this._memoryPromptHint,
  );

  final CompanionAiBridge? _bridge;
  final Future<String?> Function(String userMessage) _styleHint;
  final Future<String?> Function() _personality;
  final Future<({OrResponseDepth depth, bool spoken})> Function()? _lengthPrefs;
  final String? Function()? _memoryPromptHint;

  Future<({CompanionResponse response, bool fromAi})> complete({
    required InsightRequest request,
    required ReflectionContext context,
    required List<AIMessage> prior,
    OracleReadingContext? readingContext,
  }) async {
    final history = _priorTurns(prior, request.text);
    final turns = ConversationTurn.takeRecent(history);
    final priorUser = CompanionTurnWindow.userTexts(turns);
    final safety = SensitiveTopicGate.maybeRespond(request.text);
    if (safety != null) {
      return (response: CompanionResponse(body: safety), fromAi: false);
    }
    final personality = await _personality();
    final prefs =
        await _lengthPrefs?.call() ??
        (depth: OrResponseDepth.fallback, spoken: false);
    final depth = OrResponseLengthIntelligence.select(
      userMessage: request.text,
      preference: prefs.depth,
      turns: turns,
      spoken: prefs.spoken,
    );
    final bridge = _bridge;
    if (bridge == null) {
      throw AiRequestException(AiFailure.noConfiguration());
    }
    assert(() {
      debugPrint(
        '[OR] bridge stage=requestStart configured=${bridge.isConfigured} '
        'depth=${depth.name} pref=${prefs.depth.name} '
        'askOracle=${readingContext != null}',
      );
      return true;
    }());
    String? memHint;
    try {
      memHint = _memoryPromptHint?.call();
    } catch (_) {}
    final live = await bridge.tryLiveOrFailClosed(
      userMessage: request.text,
      priorUser: priorUser,
      turns: turns,
      styleHint: OrContextSelectionEngine.styleHint(
        currentMessage: request.text,
        recentMessages: turns,
        fullHistory: history,
        reflection: context,
        discoveryHint: await _styleHint(request.text),
        memoryPromptHint: memHint,
      ),
      personality: personality,
      depth: depth,
      spoken: prefs.spoken,
      readingContext: readingContext,
    );
    if (live == null) {
      throw AiRequestException(AiFailure.noConfiguration());
    }
    return (response: CompanionResponse(body: live), fromAi: true);
  }

  static List<ConversationTurn> _priorTurns(
    List<AIMessage> prior,
    String current,
  ) {
    final history = CompanionTurnWindow.history(prior);
    final text = current.trim();
    if (history.isNotEmpty &&
        history.last.isUser &&
        history.last.text == text) {
      return history.sublist(0, history.length - 1);
    }
    return history;
  }
}
