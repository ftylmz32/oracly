/// OR-1020 — Slow mystical orb for deck selection.
library;

import 'package:flutter/material.dart';

import '../../../theme/tarot_tokens.dart';
import '../../painters/tarot_deck_orb_painter.dart';

/// Sacred selection orb — slower breath, deeper mist, halo rings.
class TarotDeckSelectionOrb extends StatefulWidget {
  const TarotDeckSelectionOrb({
    super.key,
    this.size = TarotTokens.deckSelectionOrbSize,
  });

  final double size;

  @override
  State<TarotDeckSelectionOrb> createState() => _TarotDeckSelectionOrbState();
}

class _TarotDeckSelectionOrbState extends State<TarotDeckSelectionOrb>
    with TickerProviderStateMixin {
  late final AnimationController _glow;
  late final AnimationController _float;
  late final AnimationController _particles;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat(reverse: true);
    _float = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat(reverse: true);
    _particles = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 64),
    )..repeat();
  }

  @override
  void dispose() {
    _glow.dispose();
    _float.dispose();
    _particles.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_glow, _float, _particles]),
        builder: (context, _) {
          final floatT = Curves.easeInOut.transform(
            _float.value.clamp(0.0, 1.0),
          );
          final dy = (floatT * 2 - 1) * 5;
          final scale = 0.965 +
              Curves.easeInOut.transform(_glow.value.clamp(0.0, 1.0)) * 0.045;

          return Transform.translate(
            offset: Offset(0, dy),
            child: Transform.scale(
              scale: scale,
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: CustomPaint(
                  painter: TarotDeckOrbPainter(
                    glowPhase: _glow.value,
                    particlePhase: _particles.value * 6.28,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
