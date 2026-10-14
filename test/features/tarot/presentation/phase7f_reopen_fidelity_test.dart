/// Phase 7F — Narrative semantic roundtrip + card fidelity (no provider).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/interpretation/formatters/interpretation_formatter.dart';
import 'package:oracly_new/features/tarot/interpretation/models/interpretation_result.dart';
import 'package:oracly_new/features/tarot/narrative/result/narrative_tarot_result_bridge.dart';
import 'package:oracly_new/features/tarot/narrative/result/narrative_tarot_result_parser.dart';
import 'package:oracly_new/features/tarot/presentation/utils/reading_history_mapper.dart';
import 'package:oracly_new/features/tarot/presentation/utils/saved_reading_parser.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_narrative_selector.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_premium_body.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_result_mode.dart';

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

  testWidgets('saved single-card Narrative V2 reopens as one story safely', (
    tester,
  ) async {
    final model = ReadingModel(
      id: 'saved_single_v2',
      cardId: 5,
      cardName: 'Five of Cups',
      cardImageAsset: 'assets/cards/cups_05.webp',
      spreadType: 'single',
      aiSummary: '''
## Summary
OLD REPEATED SUMMARY

## Spread as a whole
OLD SAVED COMPLETE STORY

## Advice
OLD DISTINCT ADVICE

## Closing
OLD REPEATED CLOSING
''',
      createdAt: DateTime.utc(2026, 9, 25),
      sessionId: 'saved_single_v2',
      resultMode: 'narrativeV2',
      interpretationSource: 'ai',
      deliveryKind: 'interpretation',
      cards: const [
        ReadingCardSnapshot(
          cardId: 5,
          cardName: 'Five of Cups',
          cardImageAsset: 'assets/cards/cups_05.webp',
          positionIndex: 0,
          positionLabel: 'Sign',
          positionKey: 'sign',
          isReversed: true,
        ),
      ],
    );
    final entry = ReadingHistoryMapper.fromModel(model);
    final reopened = SavedReadingParser.toContent(entry: entry, model: model);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ReadingPremiumBody(
              content: reopened,
              spread: TarotSpreadType.single,
              modeOverride: ReadingResultMode.narrativeV2,
              showFlowProgress: false,
              sectionMaster: 1,
              panelOpacity: 1,
              ambientPhase: 0,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('OLD SAVED COMPLETE STORY'), findsWidgets);
    expect(find.textContaining('OLD DISTINCT ADVICE'), findsOneWidget);
    expect(find.textContaining('OLD REPEATED SUMMARY'), findsNothing);
    expect(find.textContaining('OLD REPEATED CLOSING'), findsNothing);
    expect(reopened.drawnCards.single.isReversed, isTrue);
    expect(tester.takeException(), isNull);
  });
}
