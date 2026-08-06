/// OR-1110 — Structured oracle response from AI pipeline.
library;

import 'ai_message.dart';

enum OracleResponseFormat { plain, markdown, structured }

class OracleResponse {
  const OracleResponse({
    required this.message,
    required this.format,
    this.suggestedFollowUps = const [],
    this.tokenUsage = 0,
    this.modelId = 'or-oracle-mock',
    this.latencyMs = 0,
  });

  final AIMessage message;
  final OracleResponseFormat format;
  final List<String> suggestedFollowUps;
  final int tokenUsage;
  final String modelId;
  final int latencyMs;

  String get text => message.content;
  List<AICitation> get citations => message.citations;
}
