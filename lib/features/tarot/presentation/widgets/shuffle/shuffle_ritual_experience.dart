/// OR-1030 — Core shuffle ritual animation layer.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/copy/first_session_copy.dart';
import '../../../../../core/first_session/first_session_scope.dart';
import 'shuffle_ambience_layer.dart';
import 'shuffle_cinematic_deck.dart';
import 'shuffle_timeline.dart';

/// Cinematic shuffle sequence — darkens, zooms deck, shuffles, shows message.
class ShuffleRitualExperience extends StatefulWidget {
  const ShuffleRitualExperience({
    super.key,
    required this.onComplete,
    this.includeBackgroundDim = true,
  });

  final VoidCallback onComplete;
  final bool includeBackgroundDim;

  @override
  State<ShuffleRitualExperience> createState() => _ShuffleRitualExperienceState();
}

class _ShuffleRitualExperienceState extends State<ShuffleRitualExperience>
    with SingleTickerProviderStateMixin {
  late final AnimationController _master;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _master = AnimationController(
      vsync: this,
      duration: ShuffleTimeline.totalDuration,
    );
    _master.addStatusListener(_onStatus);
    _master.forward();
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _completed || !mounted) return;
    _completed = true;
    widget.onComplete();
  }

  @override
  void dispose() {
    _master.removeStatusListener(_onStatus);
    _master.dispose();
    super.dispose();
  }

  void _skipIfReady() {
    if (_completed || !mounted) return;
    if (_master.value >= 0.55) {
      _completed = true;
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _skipIfReady,
      child: AnimatedBuilder(
        animation: _master,
        builder: (context, _) {
          final t = Curves.easeInOutCubic.transform(_master.value);
          final darken = ShuffleTimeline.darkenOverlay(t);
          final message = ShuffleTimeline.messageOpacity(t);

          return Stack(
            fit: StackFit.expand,
            children: [
              if (widget.includeBackgroundDim)
                ColoredBox(
                  color: Colors.black.withValues(alpha: 0.42 * darken),
                ),
              Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final stage = Size(
                      constraints.maxWidth.clamp(0, 360),
                      280,
                    );
                    return SizedBox(
                      width: stage.width,
                      height: stage.height,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          ShuffleAmbienceLayer(progress: t, size: stage),
                          ShuffleCinematicDeck(progress: t),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: AppSpacing.xxl + AppSpacing.xl,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: message,
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
                        shadows: [
                          Shadow(
                            color: AppColors.glowPurple.withValues(alpha: 0.55),
                            blurRadius: 16,
                          ),
                          Shadow(
                            color: AppColors.gold.withValues(alpha: 0.35),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
