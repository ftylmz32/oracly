/// Presentation ritual orchestration — domain APIs called once at boundaries.
library;

import 'package:flutter/widgets.dart';

import '../domain/models/reading_session.dart';
import '../domain/models/tarot_spread.dart';
import '../presentation/widgets/card_reveal/card_reveal_spread.dart';
import '../shared/tarot_scope.dart';
import 'deck_visual_state.dart';
import 'tarot_ritual_stage.dart';

class TarotRitualController extends ChangeNotifier {
  DeckVisualState visual =
      const DeckVisualState(stage: TarotRitualStage.deckReady);
  RevealCardData? active;
  final List<RevealCardData> placed = [];
  bool domainShuffleDone = false;
  bool drawing = false;
  bool leaving = false;

  /// Visual id continuity: set before domain draw, keeps same widget tree.
  String? committedVisualId;

  void setVisual(DeckVisualState next) {
    visual = next;
    notifyListeners();
  }

  Future<void> bootstrap(BuildContext context) async {
    final reading = TarotScope.of(context).reading;
    final session = reading.session;
    if (session != null &&
        (session.flowStep == ReadingFlowStep.cardSelection ||
            session.flowStep == ReadingFlowStep.reveal)) {
      domainShuffleDone = true;
      visual = visual.copyWith(stage: TarotRitualStage.draw);
      placed.clear();
      for (final d in session.drawnCards) {
        final isCurrent = session.flowStep == ReadingFlowStep.reveal &&
            session.currentCard?.positionIndex == d.positionIndex;
        if (!isCurrent) {
          placed.add(RevealCardData.fromDrawnCard(d));
        }
      }
      notifyListeners();
      return;
    }
    if (session != null && session.flowStep == ReadingFlowStep.shuffle) {
      await prepareQuickly(context);
    }
  }

  /// Brief table prepare — domain shuffle once, skip long cut UI.
  Future<void> prepareQuickly(BuildContext context) async {
    if (domainShuffleDone) {
      visual = visual.copyWith(stage: TarotRitualStage.draw);
      notifyListeners();
      return;
    }
    final scope = TarotScope.of(context);
    visual = visual.copyWith(
      stage: TarotRitualStage.shuffle,
      shuffleProgress: 0.35,
    );
    notifyListeners();
    await scope.reading.performShuffle();
    visual = visual.copyWith(shuffleProgress: 0.85);
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (domainShuffleDone) return;
    domainShuffleDone = true;
    await scope.reading.finishShuffle();
    scope.flow.selectDrawMode(TarotDrawMode.manual);
    visual = visual.copyWith(
      stage: TarotRitualStage.draw,
      shuffleProgress: 1,
      baseOffset: Offset.zero,
    );
    notifyListeners();
  }

  void completeShuffle() {
    visual = visual.copyWith(
      stage: TarotRitualStage.cut,
      shuffleProgress: 1,
      baseOffset: Offset.zero,
    );
    notifyListeners();
  }

  Future<void> completeCut(BuildContext context) async {
    if (domainShuffleDone) return;
    domainShuffleDone = true;
    final scope = TarotScope.of(context);
    await scope.reading.finishShuffle();
    scope.flow.selectDrawMode(TarotDrawMode.manual);
    visual = visual.copyWith(
      stage: TarotRitualStage.draw,
      cutProgress: 0,
      cutSeparated: false,
      baseOffset: Offset.zero,
    );
    notifyListeners();
  }

  Future<bool> commitDraw(BuildContext context) async {
    if (drawing || leaving) return false;
    drawing = true;
    committedVisualId ??= 'top-${DateTime.now().microsecondsSinceEpoch}';
    notifyListeners();
    try {
      final drawn = await TarotScope.of(context).reading.drawCard();
      active = RevealCardData.fromDrawnCard(drawn);
      visual = visual.copyWith(
        stage: TarotRitualStage.reveal,
        dragProgress: 1,
        extractionProgress: 0,
        flipProgress: 0,
        stackDepth: (visual.stackDepth - 0.08).clamp(0.4, 1.0),
      );
      notifyListeners();
      return true;
    } catch (_) {
      visual = visual.copyWith(dragProgress: 0, stage: TarotRitualStage.draw);
      committedVisualId = null;
      notifyListeners();
      return false;
    } finally {
      drawing = false;
      notifyListeners();
    }
  }

  /// Returns true when all cards drawn / reading ready (on-table overlay).
  Future<bool> settleAfterReveal(BuildContext context) async {
    final card = active;
    if (card == null) return false;
    placed.add(card);
    active = null;
    committedVisualId = null;
    visual = visual.copyWith(
      stage: TarotRitualStage.place,
      dragProgress: 0,
      extractionProgress: 0,
      flipProgress: 0,
    );
    notifyListeners();
    final reading = TarotScope.of(context).reading;
    await reading.advanceAfterReveal();
    final session = reading.session;
    if (session == null) return false;
    if (session.flowStep == ReadingFlowStep.reading || session.allCardsDrawn) {
      return true;
    }
    visual = visual.copyWith(stage: TarotRitualStage.draw);
    notifyListeners();
    return false;
  }
}
