/// Physical deck stack ? one Oracly back, visible depth layers.
library;

import "package:flutter/material.dart";

import "../deck_visual_state.dart";
import "ritual_card_shell.dart";

class RitualDeckStack extends StatelessWidget {
  const RitualDeckStack({
    super.key,
    required this.visual,
    this.packetOffset = Offset.zero,
    this.layers = 5,
    this.opacity = 1,
  });

  final DeckVisualState visual;
  final Offset packetOffset;
  final int layers;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final depth = visual.stackDepth.clamp(0.35, 1.0);
    final count = (layers * depth).round().clamp(2, 7);
    return Opacity(
      opacity: opacity,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, visual.perspective)
          ..rotateX(-0.08 * visual.shuffleProgress)
          ..rotateZ(0.04 * visual.shuffleProgress),
        child: SizedBox(
          width: RitualCardMetrics.width + 10,
          height: RitualCardMetrics.height + 14,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (var i = count - 1; i >= 0; i--)
                Transform.translate(
                  offset: packetOffset +
                      visual.baseOffset +
                      Offset(i * 1.4, i * 2.2),
                  child: RitualCardBack(
                    width: RitualCardMetrics.width - i * 0.4,
                    height: RitualCardMetrics.height - i * 0.4,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
