/// Center deck + single persistent [CardFlightActor].
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../presentation/widgets/card_reveal/card_reveal_spread.dart';
import '../../presentation/widgets/deck/tarot_deck_table_atmosphere.dart';
import '../tarot_ritual_controller.dart';
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
  final ValueChanged<RevealCardData> onFlightComplete;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          const TarotDeckTableAtmosphere(width: 260, height: 120),
          Transform.translate(
            offset: Offset(0, 14 + 8 * (1 - ritual.visual.stackDepth)),
            child: RitualDeckStack(visual: ritual.visual, layers: 6),
          ),
          if (showFlight)
            CardFlightActor(
              key: flightKey,
              enabled: phase == TarotTablePhase.draw,
              reducedMotion: reducedMotion,
              placeTarget: placeTarget,
              onInteracted: onInteracted,
              onDragVisual: (p) =>
                  ritual.setVisual(ritual.visual.copyWith(dragProgress: p)),
              onRequestDraw: onRequestDraw,
              onFlightComplete: onFlightComplete,
            ),
          if (phase == TarotTablePhase.preparing)
            Text(
              'Desten hazırlanıyor…',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}
