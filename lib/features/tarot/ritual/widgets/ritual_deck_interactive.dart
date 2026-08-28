/// Stage-specific interactive deck wrappers.
library;

import 'package:flutter/material.dart';

import '../gestures/ritual_cut_gesture.dart';
import '../gestures/ritual_draw_gesture.dart';
import '../gestures/ritual_shuffle_gesture.dart';
import '../tarot_ritual_controller.dart';
import '../tarot_ritual_stage.dart';
import 'ritual_card_shell.dart';
import 'ritual_deck_stack.dart';

class RitualDeckInteractive extends StatelessWidget {
  const RitualDeckInteractive({
    super.key,
    required this.controller,
    required this.onShuffleComplete,
    required this.onCutComplete,
    required this.onDrawCommit,
  });

  final TarotRitualController controller;
  final VoidCallback onShuffleComplete;
  final VoidCallback onCutComplete;
  final VoidCallback onDrawCommit;

  @override
  Widget build(BuildContext context) {
    final visual = controller.visual;
    final cutDx = visual.cutSeparated
        ? 78.0 * visual.cutProgress.clamp(0.35, 1)
        : 0.0;
    final dragLift =
        -RitualCardMetrics.height * 0.55 * visual.dragProgress.clamp(0.0, 1.0);

    if (visual.stage == TarotRitualStage.shuffle) {
      return RitualShuffleGesture(
        enabled: true,
        onVisual: (p) => controller.setVisual(
          visual.copyWith(
            shuffleProgress: p,
            baseOffset: Offset(12 * (p % 1), -6 * (p % 1)),
          ),
        ),
        onComplete: onShuffleComplete,
        child: RitualDeckStack(visual: visual),
      );
    }
    if (visual.stage == TarotRitualStage.cut) {
      return RitualCutGesture(
        enabled: true,
        onVisual: (p, sep) => controller.setVisual(
          visual.copyWith(cutProgress: p, cutSeparated: sep),
        ),
        onComplete: onCutComplete,
        child: Stack(
          alignment: Alignment.center,
          children: [
            RitualDeckStack(
              visual: visual,
              packetOffset: Offset(-cutDx, 10),
              layers: 3,
            ),
            RitualDeckStack(
              visual: visual,
              packetOffset: Offset(cutDx, -4),
              layers: 4,
            ),
          ],
        ),
      );
    }
    if (visual.stage == TarotRitualStage.draw) {
      return RitualDrawGesture(
        enabled: !controller.drawing,
        onVisual: (p) =>
            controller.setVisual(visual.copyWith(dragProgress: p)),
        onCommit: onDrawCommit,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Transform.translate(
              offset: const Offset(0, 18),
              child: RitualDeckStack(visual: visual, layers: 4),
            ),
            Transform.translate(
              offset: Offset(0, dragLift),
              child: const RitualCardBack(),
            ),
          ],
        ),
      );
    }
    return RitualDeckStack(visual: visual);
  }
}
