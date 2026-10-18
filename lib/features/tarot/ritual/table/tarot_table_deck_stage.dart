/// Center deck + single persistent [CardFlightActor].
library;

import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../presentation/widgets/card_reveal/card_reveal_spread.dart';
import '../../presentation/widgets/deck/tarot_deck_table_atmosphere.dart';
import '../tarot_ritual_controller.dart';
import '../widgets/ritual_card_shell.dart';
import '../widgets/ritual_deck_stack.dart';
import 'card_flight_actor.dart';
import 'tarot_table_phase.dart';

class TarotTableDeckStage extends StatelessWidget {
  const TarotTableDeckStage({
    super.key,
    required this.ritual,
    required this.phase,
    required this.flightKey,
    required this.showFlight,
    required this.reducedMotion,
    required this.placeTarget,
    required this.onInteracted,
    required this.onRequestDraw,
    required this.onFlightComplete,
  });

  final TarotRitualController ritual;
  final TarotTablePhase phase;
  final GlobalKey<CardFlightActorState> flightKey;
  final bool showFlight;
  final bool reducedMotion;
  final Offset? placeTarget;
  final VoidCallback onInteracted;
  final Future<RevealCardData?> Function() onRequestDraw;
  final Future<void> Function(RevealCardData) onFlightComplete;

  /// Vertical room the deck needs at full size: card + stack depth + the
  /// lift a drawn card travels before it settles.
  static const double _fullHeightBudget = RitualCardMetrics.height + 96;
  static const double _fullWidthBudget = RitualCardMetrics.width + 96;
  static const double _minScale = 0.62;

  /// Tall phones get a slightly larger card so the deck owns the table.
  static const double _maxScale = 1.12;

  static double scaleFor(Size available) {
    if (!available.height.isFinite || !available.width.isFinite) return 1;
    final s = [
      available.height / _fullHeightBudget,
      available.width / _fullWidthBudget,
      _maxScale,
    ].reduce((a, b) => a < b ? a : b);
    return s.clamp(_minScale, _maxScale);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = scaleFor(constraints.biggest);
        // Flight targets are authored in unscaled table space; keep their
        // on-screen destination stable when the stage shrinks.
        final target = placeTarget == null ? null : placeTarget! / scale;
        return Center(
          child: AnimatedScale(
            scale: scale,
            duration: reducedMotion
                ? Duration.zero
                : const Duration(milliseconds: 360),
            curve: Curves.easeOutCubic,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Cloth sits under the deck's base, not behind its middle.
                Transform.translate(
                  offset: const Offset(0, RitualCardMetrics.height * 0.46),
                  child: const TarotDeckTableAtmosphere(
                    width: RitualCardMetrics.width * 1.7,
                    height: RitualCardMetrics.width * 0.5,
                    intensity: 0.55,
                  ),
                ),
                Transform.translate(
                  offset: Offset(0, 14 + 8 * (1 - ritual.visual.stackDepth)),
                  child: RitualDeckStack(visual: ritual.visual, layers: 6),
                ),
                if (showFlight)
                  CardFlightActor(
                    key: flightKey,
                    enabled: phase == TarotTablePhase.draw,
                    reducedMotion: reducedMotion,
                    placeTarget: target,
                    onInteracted: onInteracted,
                    onDragVisual: (p) => ritual
                        .setVisual(ritual.visual.copyWith(dragProgress: p)),
                    onRequestDraw: onRequestDraw,
                    onFlightComplete: onFlightComplete,
                  ),
                if (phase == TarotTablePhase.preparing)
                  Text(
                    OraclyL10n.t('tarot.ritual.deck_preparing'),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
