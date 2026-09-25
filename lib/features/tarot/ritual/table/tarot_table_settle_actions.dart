/// Transactional settle + retry for [TarotTableScene] (Phase 7D.1).
library;

import 'package:flutter/material.dart';

import '../../../../core/copy/reading_flow_copy.dart';
import '../../../../core/copy/resilience_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/ui/oracly_snackbar.dart';
import '../../presentation/widgets/card_reveal/card_reveal_spread.dart';
import '../../shared/tarot_scope.dart';
import '../ritual_settle_outcome.dart';
import '../tarot_ritual_settle.dart';
import 'tarot_table_phase.dart';
import 'tarot_table_scene_state.dart';

mixin TarotTableSettleActions on TarotTableSceneActions {
  bool _settleUiInFlight = false;

  /// Awaitable settle boundary — never fire-and-forget.
  @override
  Future<void> onFlightComplete(RevealCardData data) => _runSettle(data);

  Future<void> _runSettle(RevealCardData data) async {
    if (_settleUiInFlight) return;
    _settleUiInFlight = true;
    try {
      final outcome = await ritual.settleAfterReveal(context);
      if (!mounted) return;
      switch (outcome) {
        case RitualSettleOutcome.busy:
          return;
        case RitualSettleOutcome.failed:
          _surfaceSettleRetry(data);
          return;
        case RitualSettleOutcome.readingReady:
          final count = spread?.cardCount ??
              TarotScope.maybeOf(context)?.reading.session?.spread.cardCount ??
              1;
          if (count > 1) {
            flightKey.currentState?.resetForNextDraw();
          }
          setState(() {
            phase = TarotTablePhase.reading;
            focusCard = data;
          });
          return;
        case RitualSettleOutcome.continueDraw:
          flightKey.currentState?.resetForNextDraw();
          setState(() {});
          return;
      }
    } finally {
      _settleUiInFlight = false;
    }
  }

  void _surfaceSettleRetry(RevealCardData data) {
    OraclySnackBar.error(
      context,
      ReadingFlowCopy.revealAdvanceFailed,
      action: SnackBarAction(
        label: ResilienceCopy.retryAction,
        textColor: AppColors.goldLight,
        onPressed: () {
          _runSettle(data);
        },
      ),
    );
  }
}
