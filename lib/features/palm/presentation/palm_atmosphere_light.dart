/// Soft line-light over the palm photo — never anatomy, never a scan HUD.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/oracly_quiet_motion.dart';
import 'palm_line_light_paint.dart';

class PalmAtmosphereLight extends StatefulWidget {
  const PalmAtmosphereLight({super.key});

  @override
  State<PalmAtmosphereLight> createState() => _PalmAtmosphereLightState();
}

class _PalmAtmosphereLightState extends State<PalmAtmosphereLight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tick;

  @override
  void initState() {
    super.initState();
    _tick = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyQuietMotion.ambient(context, _tick, rest: 0.18);
  }

  @override
  void dispose() {
    _tick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _tick,
        builder: (context, _) {
          final still = OraclyQuietMotion.still(context);
          final phase = still ? 0.28 : _tick.value;
          return CustomPaint(
            painter: PalmLineLightPainter(phase: phase),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}
