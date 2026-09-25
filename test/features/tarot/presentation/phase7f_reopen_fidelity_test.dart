/// Phase 7F — Narrative semantic roundtrip + card fidelity (no provider).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/tarot/interpretation/formatters/interpretation_formatter.dart';
import 'package:oracly_new/features/tarot/interpretation/models/interpretation_result.dart';
import 'package:oracly_new/features/tarot/narrative/result/narrative_tarot_result_bridge.dart';
import 'package:oracly_new/features/tarot/narrative/result/narrative_tarot_result_parser.dart';
import 'package:oracly_new/features/tarot/presentation/utils/reading_history_mapper.dart';
import 'package:oracly_new/features/tarot/presentation/utils/saved_reading_parser.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_narrative_selector.dart';

import '../narrative_prompt/narrative_prompt_test_support.dart';
import '../narrative_result/phase6d_test_support.dart';
import '../narrative_shadow/narrative_shadow_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => OraclyL10n.bind('en'));

  test('7F Narrative semantic roundtrip via real compatibility path', () {
    final scenarios = launchScenarios();
    final scenario = scenarios.firstWhere((s) {
      final input = Map<String, dynamic>.from(s['input'] as Map);
      return input['spreadType'] == 'threeCard';
    });
    final session = sessionFromEvidence(scenario);
    final request = buildFromCorpusId(scenario['id'] as String);
    final structured = NarrativeTarotResultParser.parse(
      validResultMap(request),
    );
    final interp = NarrativeTarotResultBridge.toInterpretationResult(
      request: request,
      result: structured,
      requestId: 'req_7f',
      sessionId: session.id,
      generatedAt: DateTime.utc(2026, 9, 25),
      source: InterpretationSource.ai,
    );
    const formatter = InterpretationFormatter();
    final live = formatter.toUiContent(result: interp, session: session);
    final persisted = live.fullInterpretation ?? live.generalMeaning;

    final model = ReadingModel(
      id: session.id,
      cardId: session.drawnCards.first.card.id,
      cardName: session.drawnCards.first.card.name,
      cardImageAsset: session.drawnCards.first.card.image,
      spreadType: session.spread.name,
      aiSummary: persisted,
      createdAt: DateTime.utc(2026, 9, 25),
      sessionId: session.id,
      resultMode: 'narrativeV2',
      interpretationSource: 'ai',
      deliveryKind: 'interpretation',
      cards: [
        for (final d in session.drawnCards)
          ReadingCardSnapshot(
            cardId: d.card.id,
            cardName: d.card.name,
            cardImageAsset: d.card.image,
            positionIndex: d.positionIndex,
            positionLabel: d.positionLabel,
            positionKey: d.positionKey,
            isReversed: d.isReversed,
          ),
      ],
    );

    final entry = ReadingHistoryMapper.fromModel(model);
    final reopened = SavedReadingParser.toContent(entry: entry, model: model);
    final liveSel = ReadingNarrativeSelector.select(live);
    final reopenSel = ReadingNarrativeSelector.select(reopened);

    expect(reopenSel.primaryNarrative, liveSel.primaryNarrative);
    expect(reopenSel.openingSummary, liveSel.openingSummary);
    expect(reopenSel.direction, liveSel.direction);
    expect(reopened.drawnCards.length, live.drawnCards.length);
    expect(
      reopened.drawnCards.map((c) => c.card.id).toList(),
      live.drawnCards.map((c) => c.card.id).toList(),
    );
    expect(
      reopened.drawnCards.map((c) => c.positionIndex).toList(),
      live.drawnCards.map((c) => c.positionIndex).toList(),
    );
    // positionKey when persisted on the model snapshot.
    expect(
      model.cards.map((c) => c.positionKey).toList(),
      session.drawnCards.map((c) => c.positionKey).toList(),
    );
    expect(
      reopened.drawnCards.map((c) => c.positionKey).toList(),
      model.cards.map((c) => c.positionKey).toList(),
    );
    expect(
      reopened.drawnCards.map((c) => c.isReversed).toList(),
      live.drawnCards.map((c) => c.isReversed).toList(),
    );
    expect(model.spreadType, session.spread.name);
    expect(model.resultMode, 'narrativeV2');
    expect(model.interpretationSource, 'ai');
    expect(model.deliveryKind, 'interpretation');
    expect(reopened.sourceAttributionKnown, isTrue);
    expect(reopened.isAiInterpretation, isTrue);
  });
}
