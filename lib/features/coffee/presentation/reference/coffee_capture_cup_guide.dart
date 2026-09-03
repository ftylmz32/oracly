/// Cup-interior framing stage — Coffee capture guidance only.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/oracly_quiet_motion.dart';
import 'coffee_capture_cup_guide_painter.dart';

class CoffeeCaptureCupGuide extends StatefulWidget {
  const CoffeeCaptureCupGuide({super.key});

  @override
  State<CoffeeCaptureCupGuide> createState() => _CoffeeCaptureCupGuideState();
}

class _CoffeeCaptureCupGuideState extends State<CoffeeCaptureCupGuide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyQuietMotion.ambient(context, _breath, rest: 0.14);
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = (w * 0.86).clamp(228.0, 300.0);
        return SizedBox(
          width: w,
          height: h,
          child: AnimatedBuilder(
            animation: _breath,
            builder: (context, _) {
              final pulse = OraclyQuietMotion.still(context)
                  ? 0.14
                  : 0.5 + math.sin(_breath.value * math.pi * 2) * 0.5;
              return RepaintBoundary(
                child: CustomPaint(
                  painter: CoffeeCaptureCupGuidePainter(pulse: pulse),
                ),
              );
            },
          ),
        );
      },
    );
  }
}