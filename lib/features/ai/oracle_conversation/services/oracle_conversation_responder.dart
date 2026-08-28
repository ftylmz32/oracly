/// OR-1190 / RC-002 — Context-aware oracle responses (reflective companion).
library;

import '../../../../core/copy/conversation_copy.dart';
import '../../services/conversation_response_guard.dart';
import '../models/oracle_reading_context.dart';
import 'oracle_followup_copy.dart';
import 'oracle_tarot_followup_copy.dart';

abstract final class OracleConversationSuggestions {
  OracleConversationSuggestions._();

  static List<String> get chips => ConversationCopy.oracleSuggestions;

  static List<String> chipsFor(OracleReadingKind kind) => switch (kind) {
        OracleReadingKind.coffee ||
        OracleReadingKind.palm =>
          ConversationCopy.coffeeOracleSuggestions,
        OracleReadingKind.dream => ConversationCopy.dreamOracleSuggestions,
        OracleReadingKind.astrology =>
          ConversationCopy.astrologyOracleSuggestions,
        OracleReadingKind.birthChart ||
        OracleReadingKind.starMap =>
          ConversationCopy.birthChartOracleSuggestions,
        OracleReadingKind.dailyMessage ||
        OracleReadingKind.discoveryJournal ||
        OracleReadingKind.soulMate =>
          ConversationCopy.oracleSuggestions,
        _ => ConversationCopy.oracleSuggestions,
      };

  static (String title, String body) emptyCopy(OracleReadingKind kind) =>
      switch (kind) {
        OracleReadingKind.coffee ||
        OracleReadingKind.palm => (
            ConversationCopy.coffeeOracleEmptyTitle,
            ConversationCopy.coffeeOracleEmptyBody,
          ),
        OracleReadingKind.dream => (
            ConversationCopy.dreamOracleEmptyTitle,
            ConversationCopy.dreamOracleEmptyBody,
          ),
        OracleReadingKind.astrology => (
            ConversationCopy.astrologyOracleEmptyTitle,
            ConversationCopy.astrologyOracleEmptyBody,
          ),
        OracleReadingKind.birthChart ||
        OracleReadingKind.starMap => (
            ConversationCopy.chartOracleEmptyTitle,
            ConversationCopy.chartOracleEmptyBody,
          ),
        _ => (
            ConversationCopy.oracleEmptyTitle,
            ConversationCopy.oracleEmptyBody,
          ),
      };
}

class OracleConversationResponder {
  const OracleConversationResponder();

  Future<String> respond({
    required OracleReadingContext context,
    required String userMessage,
    List<String> priorUser = const [],
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 480));
    return ConversationResponseGuard.polish(
      _buildResponse(context, userMessage, priorUser),
    );
  }

  Stream<String> respondStream({
    required OracleReadingContext context,
    required String userMessage,
    List<String> priorUser = const [],
  }) async* {
    final full = await respond(
      context: context,
      userMessage: userMessage,
      priorUser: priorUser,
    );
    final tokens = full.split(RegExp(r'(?<=\s)'));
    for (final token in tokens) {
      await Future<void>.delayed(const Duration(milliseconds: 32));
      yield token;
    }
  }

  String _buildResponse(
    OracleReadingContext context,
    String question,
    List<String> priorUser,
  ) {
    if (context.kind != OracleReadingKind.tarot) {
      return OracleFollowupCopy.respond(
        context: context,
        question: question,
        priorUser: priorUser,
      );
    }
    return OracleTarotFollowupCopy.respond(
      context: context,
      question: question,
      priorUser: priorUser,
    );
  }
}
