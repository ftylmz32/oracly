/// Phase 8 — fiveCard happy path (sol fixture callIndex 4).
/// REAL PROVIDER CALLS = 0.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_result_mode.dart';

import '../narrative_live/phase6f_live_support.dart';
import '../narrative_shadow/narrative_shadow_test_support.dart';
import 'tarot_e2e_harness.dart';

/// Sol psm_v2_05_five_conflict_ru — languageCode stays `ru`.
Map<String, dynamic> _cloneSolFive() {
  final clone = cloneSolStructured(callIndex: 4);
  clone['relationshipInsights'] = <dynamic>[];
  clone['recurringCardInsights'] = <dynamic>[];
  clone['recurringThemeInsights'] = <dynamic>[];
  clone['memoryInsights'] = <dynamic>[];
  clone['lifeAreas'] = <dynamic>[];
  return clone;
}

/// Cards match sol callIndex 4 coverage (major_00/11, wands_01/12, cups_09).
ReadingSession _fiveSession({String id = 'e2e_five_happy'}) => ReadingSession(
      id: id,
      deckId: 'classic',
      spread: TarotSpreadType.fiveCard,
      intention: const TarotIntention(text: '', topic: null),
      shuffleSeed: 1,
      startedAt: DateTime.utc(2026, 9, 24, 12),
      drawnCards: [
        TarotDrawnCard(
          card: ritualCard(0),
          positionIndex: 0,
          isReversed: false,
          positionKey: 'situation',
        ),
        TarotDrawnCard(
          card: ritualCard(11),
          positionIndex: 1,
          isReversed: false,
          positionKey: 'hidden_influence',
        ),
        TarotDrawnCard(
          card: ritualCard(64),
          positionIndex: 2,
          isReversed: false,
          positionKey: 'challenge',
        ),
        TarotDrawnCard(
          card: ritualCard(75),
          positionIndex: 3,
          isReversed: false,
          positionKey: 'strength',
        ),
        TarotDrawnCard(
          card: ritualCard(30),
          positionIndex: 4,
          isReversed: false,
          positionKey: 'direction',
        ),
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => OraclyL10n.bind('en'));

  test('happy fiveCard — one provider, one charge', () async {
    final world = await TarotE2eWorld.create();
    // create() binds en — sol five fixture is ru; rebind after world init.
    OraclyL10n.bind('ru');
    final ai = ScriptedNarrativeAi([AiOutcome.success(_cloneSolFive())]);
    final interp = world.interpretation(ai, world.newCache());
    final ctrl = world.controller(interp);
    final session = _fiveSession();
    await ctrl.updateSession(
      session.copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    final content = await world.completeViaController(ctrl, interp);
    expect(content, isNotNull);
    expect(content!.deliveryKind, TarotReadingDeliveryKind.interpretation);
    expect(ai.callCount, 1);
    expect(world.charge.alreadyCharged(session.id), isTrue);
    expect(ctrl.session!.drawnCards.length, 5);
    expect(ctrl.session!.interpretationResultMode, 'narrativeV2');
    expect(
      ReadingResultModeResolver.of(TarotSpreadType.fiveCard),
      ReadingResultMode.narrativeV2,
    );
    ctrl.dispose();
  });
}
