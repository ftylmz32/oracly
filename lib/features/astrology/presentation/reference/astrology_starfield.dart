/// Subtle parallax starfield - one ticker, quiet-motion aware.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/oracly_quiet_motion.dart';
import 'astrology_starfield_painter.dart';

class AstrologyStarfield extends StatefulWidget {
  const AstrologyStarfield({
    super.key,
    this.intensity = 1.0,
  });

  final double intensity;

  @override
  State<AstrologyStarfield> createState() => _AstrologyStarfieldState();
}

class _AstrologyStarfieldState extends State<AstrologyStarfield>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 56),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyQuietMotion.ambient(context, _drift, rest: 0.35);
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = OraclyQuietMotion.still(context);

    Widget field(double phase) => RepaintBoundary(
          child: CustomPaint(
            painter: AstrologyStarfieldPainter(
              phase: phase,
              intensity: widget.intensity,
              still: still,
            ),
            size: Size.infinite,
          ),
        );

    return IgnorePointer(
      child: still
          ? field(0.35)
          : AnimatedBuilder(
              animation: _drift,
              builder: (context, _) => field(_drift.value),
            ),
    );
  }
}
