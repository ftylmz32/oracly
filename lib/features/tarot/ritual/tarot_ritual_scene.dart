/// Visual composition for the continuous ritual host.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../shared/tarot_scope.dart';
import 'tarot_ritual_controller.dart';
import 'tarot_ritual_copy.dart';
import 'tarot_ritual_stage.dart';
import 'widgets/ritual_card_shell.dart';
import 'widgets/ritual_deck_interactive.dart';
import 'widgets/ritual_flip_card.dart';
import 'widgets/ritual_spread_slots.dart';

class TarotRitualScene extends StatelessWidget {
  const TarotRitualScene({
    super.key,
    required this.controller,
    required this.extract,
    required this.flip,
    required this.onShuffleComplete,
    required this.onCutComplete,
    required this.onDrawCommit,
  });

  final TarotRitualController controller;
  final AnimationController extract;
  final AnimationController flip;
  final VoidCallback onShuffleComplete;
  final VoidCallback onCutComplete;
  final VoidCallback onDrawCommit;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final total =
        TarotScope.of(context).reading.session?.spread.cardCount ?? 1;

    return AnimatedBuilder(
      animation: Listenable.merge([extract, flip, c]),
      builder: (context, _) {
        return Column(
          children: [
            const SizedBox(height: 12),
            Text(
              TarotRitualCopy.prompt(c.visual.stage),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            if (total > 1) ...[
              RitualSpreadSlots(placed: c.placed, totalSlots: total),
              const SizedBox(height: 24),
            ],
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    if (c.active == null)
                      RitualDeckInteractive(
                        controller: c,
                        onShuffleComplete: onShuffleComplete,
                        onCutComplete: onCutComplete,
                        onDrawCommit: onDrawCommit,
                      ),
                    if (c.active != null)
                      Transform.translate(
                        offset: Offset(0, -110 * extract.value),
                        child: RitualFlipCard(
                          flipProgress: flip.value,
                          label: c.active!.displayName,
                          image: c.active!.imageAsset,
                          reversed: c.active!.isReversed,
                        ),
                      ),
                    if (total == 1 &&
                        c.placed.isNotEmpty &&
                        c.active == null &&
                        c.visual.stage == TarotRitualStage.place)
                      RitualCardFace(
                        label: c.placed.last.displayName,
                        image: c.placed.last.imageAsset,
                        reversed: c.placed.last.isReversed,
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
