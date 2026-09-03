/// Reveal atmosphere + hero + continue panel — no card/title collision.
library;

import 'package:flutter/material.dart';

import '../../../../../core/design_system/app_layout.dart';
import 'card_reveal_hero.dart';
import 'card_reveal_spread.dart';
import 'reveal_atmospheric_light.dart';
import 'reveal_background.dart';
import 'reveal_result_panel.dart';
import 'reveal_timeline.dart';

class CardRevealStage extends StatelessWidget {
  const CardRevealStage({
    super.key,
    required this.progress,
    required this.data,
    required this.onContinue,
    this.completionHint,
    this.continueBusy = false,
    this.continueError,
  });

  final double progress;
  final RevealCardData data;
  final VoidCallback onContinue;
  final String? completionHint;
  final bool continueBusy;
  final String? continueError;

  @override
  Widget build(BuildContext context) {
    final t = progress;
    final stillness = RevealTimeline.anticipationStillness(t);
    final deepen = RevealTimeline.ambientDeepen(t);
    final light = RevealTimeline.atmosphericLight(t);
    final focus = RevealTimeline.orbFocus(t);
    final inherited =
        (stillness +
                0.14 *
                    (1 -
                        (t.clamp(0.0, RevealTimeline.pauseEnd) /
                                RevealTimeline.pauseEnd)
                            .clamp(0.0, 1.0)))
            .clamp(0.0, 1.0);
    final bottomReserve = AppLayout.scrollBottomInset(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: RevealBackground(
            darken: RevealTimeline.darken(t),
            stillness: stillness,
            ambientDeepen: deepen,
          ),
        ),
        if (inherited > 0.04)
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: inherited * 0.18),
              ),
            ),
          ),
        if (deepen > 0.02)
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: deepen * 0.08),
              ),
            ),
          ),
        Positioned.fill(
          child: RevealAtmosphericLight(intensity: light, focus: focus),
        ),
        // Card stays in the upper ceremony zone — never under the panel.
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: 168 + bottomReserve * 0.35,
          child: Align(
            alignment: const Alignment(0, -0.18),
            child: Transform.scale(
              scale: RevealTimeline.cameraZoom(t),
              child: RepaintBoundary(
                child: CardRevealHero(progress: t, data: data),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomReserve),
              child: RevealResultPanel(
                data: data,
                nameOpacity: RevealTimeline.nameOpacity(t),
                subtitleOpacity: RevealTimeline.subtitleOpacity(t),
                badgeOpacity: RevealTimeline.badgeOpacity(t),
                buttonOpacity: RevealTimeline.buttonOpacity(t),
                buttonSlide: RevealTimeline.buttonSlide(t),
                onContinue: onContinue,
                completionHint: completionHint,
                continueBusy: continueBusy,
                continueError: continueError,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
