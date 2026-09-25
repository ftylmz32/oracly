/// Phase 7G — deterministic saved-reading fixtures for history goldens.
library;

import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/core/domain/models/ritual_journal_metadata.dart';
import 'package:oracly_new/features/tarot/presentation/utils/reading_history_mapper.dart';
import 'package:oracly_new/features/tarot/presentation/utils/saved_reading_parser.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/reading_history/reading_history_data.dart';

import 'tarot_visual_fixtures.dart';

ReadingCardSnapshot _snap(int index, {bool reversed = false}) {
  final face = tarotVisualReveal(index, reversed: reversed);
  return ReadingCardSnapshot(
    cardId: face.card.id,
    cardName: face.displayName,
    cardImageAsset: face.imageAsset,
    positionIndex: index,
    positionLabel: 'P$index',
    positionKey: 'p$index',
    isReversed: reversed,
  );
}

ReadingModel tarotGoldenReadingModel({
  required String id,
  required String spreadType,
  required String cardName,
  required String resultMode,
  required String interpretationSource,
  required String deliveryKind,
  required List<ReadingCardSnapshot> cards,
  String aiSummary =
      '## Summary\nA short opening lead about patience.\n\n'
      '## The spread as a whole\n'
      'The longer primary synthesis holds the main story body with several '
      'calm reflective sentences about the threshold.\n\n'
      '## Closing\nOne honest step today is enough.',
  bool favorite = false,
  String? note,
}) {
  final primaryImage = cards.isEmpty
      ? tarotVisualReveal(0).imageAsset
      : cards.first.cardImageAsset;
  return ReadingModel(
    id: id,
    cardId: cards.isEmpty ? tarotVisualReveal(0).card.id : cards.first.cardId,
    cardName: cardName,
    cardImageAsset: primaryImage,
    spreadType: spreadType,
    aiSummary: aiSummary,
    createdAt: DateTime.utc(2026, 9, 25, 14, 30),
    resultMode: resultMode,
    interpretationSource: interpretationSource,
    deliveryKind: deliveryKind,
    cards: cards,
    journal: RitualJournalMetadata(
      isFavorite: favorite,
      personalNote: note,
      summaryExcerpt: 'A short opening lead about patience.',
      emotionalKeywords: const ['Calm', 'Threshold'],
    ),
  );
}

List<ReadingHistoryEntry> tarotGoldenMixedHistoryEntries() {
  final models = [
    tarotGoldenReadingModel(
      id: 'h_single',
      spreadType: 'single',
      cardName: 'The Star',
      resultMode: 'narrativeV2',
      interpretationSource: 'ai',
      deliveryKind: 'interpretation',
      cards: [_snap(0)],
      favorite: true,
      note: 'Kept this quietly.',
    ),
    tarotGoldenReadingModel(
      id: 'h_three',
      spreadType: 'threeCard',
      cardName: 'The Moon',
      resultMode: 'narrativeV2',
      interpretationSource: 'ai',
      deliveryKind: 'interpretation',
      cards: [_snap(0), _snap(1, reversed: true), _snap(2)],
    ),
    tarotGoldenReadingModel(
      id: 'h_five',
      spreadType: 'fiveCard',
      cardName: 'The Sun',
      resultMode: 'narrativeV2',
      interpretationSource: 'ai',
      deliveryKind: 'interpretation',
      cards: [for (var i = 0; i < 5; i++) _snap(i, reversed: i == 1)],
    ),
    tarotGoldenReadingModel(
      id: 'h_seven',
      spreadType: 'sevenCard',
      cardName: 'The Hermit',
      resultMode: 'legacy',
      interpretationSource: 'local',
      deliveryKind: 'interpretation',
      cards: [for (var i = 0; i < 3; i++) _snap(i)],
    ),
    tarotGoldenReadingModel(
      id: 'h_celtic',
      spreadType: 'celticCross',
      cardName: 'The Lovers',
      resultMode: 'legacy',
      interpretationSource: 'local',
      deliveryKind: 'interpretation',
      cards: [for (var i = 0; i < 3; i++) _snap(i)],
    ),
    tarotGoldenReadingModel(
      id: 'h_cross',
      spreadType: 'crossroads',
      cardName: 'The Fool',
      resultMode: 'legacy',
      interpretationSource: 'local',
      deliveryKind: 'interpretation',
      cards: [for (var i = 0; i < 5; i++) _snap(i, reversed: i == 2)],
    ),
  ];
  return [for (final m in models) ReadingHistoryMapper.fromModel(m)];
}

({ReadingHistoryEntry entry, ReadingModel model, AiReadingContent content})
    tarotGoldenHistoryNarrativeDetail() {
  final model = tarotGoldenReadingModel(
    id: 'detail_v2',
    spreadType: 'threeCard',
    cardName: 'The Star',
    resultMode: 'narrativeV2',
    interpretationSource: 'ai',
    deliveryKind: 'interpretation',
    cards: [_snap(0), _snap(1, reversed: true), _snap(2)],
    note: 'A personal note.',
  );
  // Prefer live Narrative fixture text for visual hierarchy.
  final live = tarotVisualNarrativeContent(
    spreadLabel: 'Three Card',
    cardCount: 3,
    question: 'Where am I between past and next step?',
  );
  final withText = ReadingModel(
    id: model.id,
    cardId: model.cardId,
    cardName: model.cardName,
    cardImageAsset: model.cardImageAsset,
    spreadType: model.spreadType,
    aiSummary: live.fullInterpretation ??
        '## Summary\n${live.generalMeaning}\n\n'
            '## The spread as a whole\n${live.luckyEnergy}\n\n'
            '## Closing\n${live.closingMessage}',
    createdAt: model.createdAt,
    resultMode: model.resultMode,
    interpretationSource: model.interpretationSource,
    deliveryKind: model.deliveryKind,
    cards: model.cards,
    journal: model.journal,
  );
  final entry = ReadingHistoryMapper.fromModel(withText);
  final content = SavedReadingParser.toContent(entry: entry, model: withText);
  return (entry: entry, model: withText, content: content);
}

({ReadingHistoryEntry entry, ReadingModel model, AiReadingContent content})
    tarotGoldenHistoryCrossroadsDetail() {
  final model = tarotGoldenReadingModel(
    id: 'detail_cross',
    spreadType: 'crossroads',
    cardName: 'The Star',
    resultMode: 'legacy',
    interpretationSource: 'local',
    deliveryKind: 'interpretation',
    cards: [for (var i = 0; i < 5; i++) _snap(i, reversed: i == 1)],
  );
  final entry = ReadingHistoryMapper.fromModel(model);
  final content = SavedReadingParser.toContent(entry: entry, model: model);
  return (entry: entry, model: model, content: content);
}
