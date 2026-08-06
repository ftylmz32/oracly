/// OR-1110 — Parses raw AI responses into structured oracle output.
library;

import '../domain/models/ai_message.dart';
import '../domain/models/oracle_response.dart';

abstract final class ResponseParser {
  ResponseParser._();

  static OracleResponse parse({
    required String rawText,
    required String messageId,
    OracleResponseFormat format = OracleResponseFormat.markdown,
    List<String> suggestedFollowUps = const [],
    int tokenUsage = 0,
    int latencyMs = 0,
  }) {
    final citations = _extractCitations(rawText);
    final cleaned = _stripCitationMarkers(rawText);

    return OracleResponse(
      message: AIMessage(
        id: messageId,
        role: AIMessageRole.assistant,
        content: cleaned,
        createdAt: DateTime.now(),
        status: AIMessageStatus.completed,
        citations: citations,
        tokenCount: tokenUsage,
      ),
      format: format,
      suggestedFollowUps: suggestedFollowUps,
      tokenUsage: tokenUsage,
      latencyMs: latencyMs,
    );
  }

  static List<AICitation> _extractCitations(String text) {
    final matches = RegExp(r'\[\^(\d+)\]: (.+)').allMatches(text);
    return matches
        .map(
          (m) => AICitation(
            label: m.group(1)!,
            source: m.group(2)!.trim(),
          ),
        )
        .toList();
  }

  static String _stripCitationMarkers(String text) {
    return text.replaceAll(RegExp(r'\[\^\d+\]'), '').trim();
  }
}
