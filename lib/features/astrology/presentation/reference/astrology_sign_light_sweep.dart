/// Brief gold light sweep when the selected sign changes.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_motion.dart';
import '../../../../core/theme/oracly_quiet_motion.dart';

class AstrologySignLightSweep extends StatefulWidget {
  const AstrologySignLightSweep({super.key, required this.signId});

  final String signId;

  @override
  State<AstrologySignLightSweep> createState() =>
      _AstrologySignLightSweepState();
}

class _AstrologySignLightSweepState extends State<AstrologySignLightSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep;

  @override
  void initState() {
    super.initState();
    _sweep = AnimationController(
      vsync: this,
      duration: AppMotionDuration.slow,
    );
  }

  @override
  void didUpdateWidget(covariant AstrologySignLightSweep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.signId == widget.signId) return;
    if (OraclyQuietMotion.still(context)) return;
    _sweep.forward(from: 0);
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (OraclyQuietMotion.still(context)) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _sweep,
        builder: (context, _) {
          if (_sweep.value <= 0.01 || _sweep.value >= 0.99) {
            return const SizedBox.shrink();
          }
          final t = Curves.easeInOutCubic.transform(_sweep.value);
          final shear = -0.85 + t * 1.7;
          final opacity = math.sin(t * math.pi) * 0.28;
          return Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(shear * 36, 0),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-0.9, -0.5),
                    end: Alignment(0.8, 0.6),
                    colors: [
                      Color(0x00FFFFFF),
                      Color(0x55FFF6E0),
                      Color(0x44E8C872),
                      Color(0x00FFFFFF),
                    ],
                    stops: [0.2, 0.44, 0.54, 0.78],
                  ),
                ),
                child: SizedBox.expand(),
              ),
            ),
          );
        },
      ),
    );
  }
}
