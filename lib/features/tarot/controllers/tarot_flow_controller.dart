/// OR-1000 — Tarot ritual flow controller.
library;

import '../domain/models/tarot_spread.dart';
import '../theme/tarot_tokens.dart';
import 'tarot_base_controller.dart';

/// Tracks the active step in the cinematic tarot ritual pipeline.
class TarotFlowController extends TarotBaseController {
  TarotFlowStep _step = TarotFlowStep.home;
  TarotSpreadType _spread = TarotSpreadType.threeCard;
  TarotIntention _intention = const TarotIntention(text: '');

  TarotFlowStep get step => _step;
  TarotSpreadType get spread => _spread;
  TarotIntention get intention => _intention;

  void goTo(TarotFlowStep step) {
    if (_step == step) return;
    _step = step;
    notifyListeners();
  }

  void selectSpread(TarotSpreadType spread) {
    _spread = spread;
    notifyListeners();
  }

  void setIntention(TarotIntention intention) {
    _intention = intention;
    notifyListeners();
  }

  void reset() {
    _step = TarotFlowStep.home;
    _spread = TarotSpreadType.threeCard;
    _intention = const TarotIntention(text: '');
    clearError();
    notifyListeners();
  }
}
