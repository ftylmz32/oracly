/// OR-1190 — Reading context bound to an oracle conversation.
library;

import 'package:flutter/foundation.dart';

import '../../../tarot/domain/models/reading_session.dart';
import '../../../tarot/interpretation/models/interpretation_result.dart';
import '../../../tarot/presentation/widgets/ai_reading/ai_reading_content.dart';

@immutable
class OracleReadingContext {
  const OracleReadingContext({
    required this.sessionId,
    required this.spreadLabel,
    required this.deckId,
    required this.deckName,
    required this.readingTitle,
    required this.cardsSummary,
    required this.interpretationSummary,
    this.userQuestion,
    this.fullInterpretation,
    this.cardNames = const [],
  });

  final String sessionId;
  final String spreadLabel;
  final String deckId;
  final String deckName;
  final String readingTitle;
  final String cardsSummary;
  final String interpretationSummary;
  final String? userQuestion;
  final String? fullInterpretation;
  final List<String> cardNames;

  factory OracleReadingContext.fromSession({
    required ReadingSession session,
    required AiReadingContent content,
    String deckName = 'Rider-Waite',
  }) {
    final cardsSummary = session.drawnCards
        .map(
          (d) =>
              '${d.positionLabel ?? "Kart"}: ${d.card.name} '
              '(${d.isReversed ? "Ters" : "Düz"})',
        )
        .join('\n');

    return OracleReadingContext(
      sessionId: session.id,
      spreadLabel: session.spread.label,
      deckId: session.deckId,
      deckName: deckName,
      readingTitle: content.cardName,
      cardsSummary: cardsSummary,
      interpretationSummary: content.generalMeaning,
      userQuestion: session.intention.text.trim().isEmpty
          ? null
          : session.intention.text.trim(),
      fullInterpretation: content.fullInterpretation ?? content.generalMeaning,
      cardNames: session.drawnCards.map((d) => d.card.name).toList(),
    );
  }

  factory OracleReadingContext.fromInterpretation({
    required ReadingSession session,
    required InterpretationResult result,
    String deckName = 'Rider-Waite',
  }) {
    final cardsSummary = session.drawnCards
        .map(
          (d) =>
              '${d.positionLabel ?? "Kart"}: ${d.card.name} '
              '(${d.isReversed ? "Ters" : "Düz"})',
        )
        .join('\n');

    return OracleReadingContext(
      sessionId: session.id,
      spreadLabel: session.spread.label,
      deckId: session.deckId,
      deckName: deckName,
      readingTitle: session.drawnCards.length == 1
          ? session.drawnCards.first.card.name
          : '${session.spread.label} Açılımı',
      cardsSummary: cardsSummary,
      interpretationSummary: result.summary,
      userQuestion: session.intention.text.trim().isEmpty
          ? null
          : session.intention.text.trim(),
      fullInterpretation: result.rawText ?? result.summary,
      cardNames: session.drawnCards.map((d) => d.card.name).toList(),
    );
  }

  Map<String, String> toMetadata() => {
        'sessionId': sessionId,
        'spreadLabel': spreadLabel,
        'deckId': deckId,
        'deckName': deckName,
        'readingTitle': readingTitle,
        'cardsSummary': cardsSummary,
        'interpretationSummary': interpretationSummary,
        'userQuestion': ?userQuestion,
        'fullInterpretation': ?fullInterpretation,
        'cardNames': cardNames.join('|'),
      };

  factory OracleReadingContext.fromMetadata(Map<String, String> metadata) {
    return OracleReadingContext(
      sessionId: metadata['sessionId'] ?? '',
      spreadLabel: metadata['spreadLabel'] ?? '',
      deckId: metadata['deckId'] ?? 'rider-waite',
      deckName: metadata['deckName'] ?? 'Rider-Waite',
      readingTitle: metadata['readingTitle'] ?? 'Tarot Açılımı',
      cardsSummary: metadata['cardsSummary'] ?? '',
      interpretationSummary: metadata['interpretationSummary'] ?? '',
      userQuestion: metadata['userQuestion'],
      fullInterpretation: metadata['fullInterpretation'],
      cardNames: (metadata['cardNames'] ?? '')
          .split('|')
          .where((e) => e.isNotEmpty)
          .toList(),
    );
  }
}
