/// Subtle analysis veil — photo stays primary; no fake AI theatre.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/oracly_quiet_motion.dart';
import 'coffee_analysis_veil_paint.dart';
import 'coffee_reference_tokens.dart';

class CoffeeAnalysisVeil extends StatefulWidget {
  const CoffeeAnalysisVeil({super.key, required this.child});

  final Widget child;

  @override
  State<CoffeeAnalysisVeil> createState() => _CoffeeAnalysisVeilState();
}

class _CoffeeAnalysisVeilState extends State<CoffeeAnalysisVeil>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 9200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyQuietMotion.ambient(context, _motion, rest: 0.2);
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _motion,
      builder: (context, child) {
        final still = OraclyQuietMotion.still(context);
        final t = still ? 0.22 : _motion.value;
        final focus = 1.0 + math.sin(t * math.pi * 2) * 0.012;
        final sweep = still
            ? 0.45
            : Curves.easeInOut.transform(((t * 1.15) % 1.0).clamp(0.0, 1.0));
        final progress = still ? 0.35 : Curves.easeInOutCubic.transform(t);
        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Transform.scale(scale: focus, child: child),
              IgnorePointer(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.08),
                          radius: 0.92 + math.sin(t * math.pi * 2) * 0.04,
                          colors: [
                            Colors.transparent,
                            CoffeeReferenceTokens.veilInk.withValues(
                              alpha: 0.16 + math.sin(t * math.pi * 2) * 0.04,
                            ),
                          ],
                          stops: const [0.42, 1.0],
                        ),
                      ),
                    ),
                    Opacity(
                      opacity: 0.20 + math.sin(sweep * math.pi) * 0.10,
                      child: Transform.translate(
                        offset: Offset((-0.9 + sweep * 1.8) * 48, 0),
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(-0.85, -0.4),
                              end: Alignment(0.9, 0.55),
                              colors: [
                                Color(0x00FFFFFF),
                                Color(0x33FFF1D0),
                                Color(0x28E8C872),
                                Color(0x00FFFFFF),
                              ],
                              stops: [0.22, 0.46, 0.54, 0.78],
                            ),
                          ),
                          child: SizedBox.expand(),
                        ),
                      ),
                    ),
                    CustomPaint(
                      painter: CoffeeAnalysisDustPainter(phase: t * math.pi * 2),
                    ),
                    Align(
                      alignment: const Alignment(0, 0.88),
                      child: CoffeeAnalysisQuietProgress(progress: progress),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}
