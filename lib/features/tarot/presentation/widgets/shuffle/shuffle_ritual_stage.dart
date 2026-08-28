/// Shuffle ritual stage layout — deck, ambience, cut offer.
library;

import 'package:flutter/material.dart';

import '../../../../../core/copy/first_session_copy.dart';
import '../../../../../core/first_session/first_session_scope.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'shuffle_ambience_layer.dart';
import 'shuffle_cinematic_deck.dart';
import 'shuffle_cut_offer.dart';
import 'shuffle_timeline.dart';

class ShuffleRitualStage extends StatelessWidget {
  const ShuffleRitualStage({
    super.key,
    required this.progress,
    required this.cutProgress,
    required this.dim,
    required this.offering,
    required this.onCut,
    required this.onSkip,
  });

  final double progress;
  final double cutProgress;
  final bool dim;
  final bool offering;
  final VoidCallback onCut;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final darken = ShuffleTimeline.darkenOverlay(progress);
    final message = ShuffleTimeline.messageOpacity(progress);
    return Stack(
      fit: StackFit.expand,
      children: [
        if (dim)
          ColoredBox(color: Colors.black.withValues(alpha: 0.42 * darken)),
        Center(
          child: SizedBox(
            width: 360,
            height: 280,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                ShuffleAmbienceLayer(
                  progress: progress,
                  size: const Size(360, 280),
                ),
                ShuffleCinematicDeck(
                  progress: progress,
                  cutProgress: cutProgress,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: AppSpacing.xxl + AppSpacing.xl,
          child: offering
              ? ShuffleCutOffer(onCut: onCut, onSkip: onSkip)
              : IgnorePointer(
                  child: Opacity(
                    opacity: message * (1 - cutProgress),
                    child: Text(
                      FirstSessionCopy.shuffleMessageFor(
                        isFirstSession: FirstSessionScope.of(context),
                      ),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.goldLight,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.35,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
