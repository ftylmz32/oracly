/// OR-1190 — Reading context bound to an oracle conversation.
library;

import 'package:flutter/foundation.dart';

import '../../../../core/domain/models/reading.dart';
import '../../../tarot/copy/tarot_l10n.dart';
import '../../../tarot/domain/models/reading_session.dart';
import '../../../tarot/history/tarot_history_privacy.dart';
import '../../../tarot/interpretation/models/interpretation_result.dart';
import '../../../tarot/presentation/widgets/ai_reading/ai_reading_content.dart';
import '../services/oracle_reading_context_text.dart';
import 'oracle_reading_kind.dart';

export 'oracle_reading_kind.dart';

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
    this.cardIds = const [],
    this.kind = OracleReadingKind.tarot,
    this.sourceLabel = '',
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
  final List<int> cardIds;
  final OracleReadingKind kind;
  final String sourceLabel;

  factory OracleReadingContext.fromSession({
    required ReadingSession session,
    required AiReadingContent content,
    String deckName = 'Rider-Waite',
  }) {
    final cardsSummary = OracleReadingContextText.cardsSummaryFor(session);
    final question = session.intention.text.trim();
    final summary = OracleReadingContextText.summaryFromContent(content);
    final topic = session.intention.topic ?? content.readingTheme;
    return OracleReadingContext(
      sessionId: session.id,
      spreadLabel: session.spread.label,
      deckId: session.deckId,
      deckName: deckName,
      readingTitle: content.cardName,
      cardsSummary: cardsSummary,
      interpretationSummary: summary,
      userQuestion: question.isEmpty ? null : question,
      cardNames: session.drawnCards.map((d) => d.localizedName).toList(),
      cardIds: OracleReadingContextText.cardIdsFor(session),
      kind: OracleReadingKind.tarot,
      sourceLabel: OracleReadingContextText.tarotSourceLabel(topic: topic),
    );
  }

  factory OracleReadingContext.fromHistoryReading(ReadingModel reading) {
    final names = reading.cards.isNotEmpty
        ? [for (final card in reading.cards) card.cardName]
        : [reading.cardName];
    final ids = reading.cards.isNotEmpty
        ? [for (final card in reading.cards) card.cardId]
        : [reading.cardId];
    return OracleReadingContext(
      sessionId: reading.id,
      spreadLabel: TarotHistoryPrivacy.spreadTitle(reading.spreadType),
      deckId: reading.deckId,
      deckName: 'Rider-Waite',
      readingTitle: names.length == 1 ? names.first : reading.spreadType,
      cardsSummary: names.join(', '),
      interpretationSummary: TarotHistoryPrivacy.shortInsight(reading),
      userQuestion: TarotHistoryPrivacy.questionSummary(reading.intention),
      cardNames: names,
      cardIds: ids,
      kind: OracleReadingKind.tarot,
      sourceLabel: OracleReadingContextText.tarotSourceLabel(),
    );
  }

  factory OracleReadingContext.fromInterpretation({
    required ReadingSession session,
    required InterpretationResult result,
    String deckName = 'Rider-Waite',
  }) {
    final cardsSummary = OracleReadingContextText.cardsSummaryFor(session);
    final question = session.intention.text.trim();
    return OracleReadingContext(
      sessionId: session.id,
      spreadLabel: session.spread.label,
      deckId: session.deckId,
      deckName: deckName,
      readingTitle: session.drawnCards.length == 1
          ? session.drawnCards.first.localizedName
          : TarotL10n.spreadReadingTitle(session.spread),
      cardsSummary: cardsSummary,
      interpretationSummary:
          OracleReadingContextText.shortSummary(result.summary),
      userQuestion: question.isEmpty ? null : question,
      cardNames: session.drawnCards.map((d) => d.localizedName).toList(),
      cardIds: OracleReadingContextText.cardIdsFor(session),
      kind: OracleReadingKind.tarot,
      sourceLabel: OracleReadingContextText.tarotSourceLabel(
        topic: session.intention.topic,
      ),
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
        'cardIds': cardIds.join('|'),
        'kind': kind.name,
        'sourceLabel': sourceLabel,
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
      cardIds: (metadata['cardIds'] ?? '')
          .split('|')
          .where((e) => e.isNotEmpty)
          .map(int.parse)
          .toList(),
      kind: _kindFrom(metadata['kind']),
      sourceLabel: metadata['sourceLabel'] ?? '',
    );
  }

  static OracleReadingKind _kindFrom(String? name) {
    for (final kind in OracleReadingKind.values) {
      if (kind.name == name) return kind;
    }
    return OracleReadingKind.tarot;
  }
}
