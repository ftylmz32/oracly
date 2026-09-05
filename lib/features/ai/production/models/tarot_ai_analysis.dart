/// Typed production Tarot request/response contract.
library;

import 'package:flutter/foundation.dart';

@immutable
class TarotAiCardEvidence {
  const TarotAiCardEvidence({
    required this.cardId,
    required this.cardName,
    required this.positionLabel,
    required this.positionKey,
    required this.isReversed,
    required this.meaning,
    this.keywords = const [],
  });

  final int cardId;
  final String cardName;
  final String positionLabel;
  final String positionKey;
  final bool isReversed;
  final String meaning;
  final List<String> keywords;

  Map<String, dynamic> toPayload() => {
        'cardId': cardId,
        'cardName': cardName,
        'positionLabel': positionLabel,
        'positionKey': positionKey,
        'isReversed': isReversed,
        'meaning': meaning,
        if (keywords.isNotEmpty) 'keywords': keywords,
      };
}

@immutable
class TarotAiContinuity {
  const TarotAiContinuity({
    this.recurringThemes = const [],
    this.recentCardNames = const [],
    this.hasPriorNotes = false,
    this.priorReadingCount = 0,
    this.revisitPriorExcerpt,
    this.revisitInstruction,
  });

  final List<String> recurringThemes;
  final List<String> recentCardNames;
  final bool hasPriorNotes;
  final int priorReadingCount;
  final String? revisitPriorExcerpt;
  final String? revisitInstruction;

  bool get isEmpty =>
      recurringThemes.isEmpty &&
      recentCardNames.isEmpty &&
      !hasPriorNotes &&
      priorReadingCount == 0 &&
      (revisitPriorExcerpt == null || revisitPriorExcerpt!.trim().isEmpty) &&
      (revisitInstruction == null || revisitInstruction!.trim().isEmpty);

  Map<String, dynamic> toPayload() => {
        if (recurringThemes.isNotEmpty) 'recurringThemes': recurringThemes,
        if (recentCardNames.isNotEmpty) 'recentCardNames': recentCardNames,
        if (hasPriorNotes) 'hasPriorNotes': true,
        if (priorReadingCount > 0) 'priorReadingCount': priorReadingCount,
        if ((revisitPriorExcerpt ?? '').trim().isNotEmpty)
          'revisitPriorExcerpt': revisitPriorExcerpt!.trim(),
        if ((revisitInstruction ?? '').trim().isNotEmpty)
          'revisitInstruction': revisitInstruction!.trim(),
      };
}

@immutable
class TarotAiRequestContext {
  const TarotAiRequestContext({
    required this.operationId,
    required this.sessionId,
    required this.spreadLabel,
    required this.cards,
    this.userQuestion,
    this.readingTheme,
    this.continuity = const TarotAiContinuity(),
  });

  /// One engine attempt. Retries of the same request reuse it; a genuine
  /// regenerate receives a new ID and is therefore not confused with a retry.
  final String operationId;
  final String sessionId;
  final String spreadLabel;
  final List<TarotAiCardEvidence> cards;
  final String? userQuestion;
  final String? readingTheme;
  final TarotAiContinuity continuity;
}

@immutable
class TarotAiAnalysis {
  const TarotAiAnalysis({
    required this.summary,
    required this.love,
    required this.career,
    required this.money,
    required this.health,
    required this.spiritualGuidance,
    required this.advice,
    required this.warnings,
    required this.luckyEnergy,
    required this.dailyFocus,
    required this.closingMessage,
    this.rawText,
  });

  final String summary;
  final String love;
  final String career;
  final String money;
  final String health;
  final String spiritualGuidance;
  final String advice;
  final String warnings;
  final String luckyEnergy;
  final String dailyFocus;
  final String closingMessage;
  final String? rawText;
}
