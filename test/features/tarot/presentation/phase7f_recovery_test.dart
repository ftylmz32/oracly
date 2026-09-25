/// Phase 7F — recovery reopen + source honesty (no provider / no charge).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/tarot/interpretation/models/interpretation_result.dart';
import 'package:oracly_new/features/tarot/presentation/utils/reading_history_mapper.dart';
import 'package:oracly_new/features/tarot/presentation/utils/saved_reading_parser.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';
import 'package:oracly_new/features/tarot/copy/tarot_polish_copy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => OraclyL10n.bind('en'));

  test('saved recovery reopens as recovery — not normal AI success', () {
    final model = ReadingModel(
      id: 'rec1',
      cardId: 0,
      cardName: 'The Fool',
      cardImageAsset: 'lib/assets/images/tarot/major_arcana/00_budala.png',
      spreadType: 'single',
      aiSummary: '## Summary\nA quiet recovered reflection.',
      createdAt: DateTime.utc(2026, 9, 25),
      resultMode: 'legacy',
      interpretationSource: 'local',
      deliveryKind: 'recovery',
    );
    final entry = ReadingHistoryMapper.fromModel(model);
    final content = SavedReadingParser.toContent(entry: entry, model: model);
    expect(content.deliveryKind, TarotReadingDeliveryKind.recovery);
    expect(content.isChargeEligible, isFalse);
    expect(content.isJournalEligible, isTrue);
    expect(content.generalMeaning, contains('quiet recovered'));
  });

  test('unknown provenance omits AI/local attribution claim', () {
    final model = ReadingModel(
      id: 'old1',
      cardId: 0,
      cardName: 'The Moon',
      cardImageAsset: 'lib/assets/images/tarot/major_arcana/18_ay.png',
      spreadType: 'single',
      aiSummary: '## Summary\nAn older saved reflection without provenance.',
      createdAt: DateTime.utc(2025, 1, 1),
    );
    expect(model.interpretationSource, isNull);
    final entry = ReadingHistoryMapper.fromModel(model);
    final content = SavedReadingParser.toContent(entry: entry, model: model);
    expect(content.sourceAttributionKnown, isFalse);
    final footnote = TarotPolishCopy.readingFootnote(
      fromAi: content.sourceAttributionKnown ? content.isAiInterpretation : null,
    );
    expect(footnote, TarotPolishCopy.disclaimer);
    expect(footnote.contains(TarotPolishCopy.sourceAi), isFalse);
    expect(footnote.contains(TarotPolishCopy.sourceLocal), isFalse);
  });

  test('persisted ai source reopens as ai', () {
    final model = ReadingModel(
      id: 'ai1',
      cardId: 0,
      cardName: 'The Sun',
      cardImageAsset: 'lib/assets/images/tarot/major_arcana/19_gunes.png',
      spreadType: 'single',
      aiSummary: '## Summary\nWarm AI reflection.',
      createdAt: DateTime.utc(2026, 9, 25),
      interpretationSource: InterpretationSource.ai.name,
      deliveryKind: 'interpretation',
    );
    final content = SavedReadingParser.toContent(
      entry: ReadingHistoryMapper.fromModel(model),
      model: model,
    );
    expect(content.sourceAttributionKnown, isTrue);
    expect(content.isAiInterpretation, isTrue);
  });
}
