/// Occasional gold light sweep — never a constant pulse.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/micro_details/micro_detail_painters.dart';
import '../../../core/design_system/micro_details/micro_detail_tokens.dart';
import '../../../core/theme/oracly_quiet_motion.dart';

/// Restrained sweep that appears briefly each cycle, then rests.
class HomeLivingSweep extends StatefulWidget {
  const HomeLivingSweep({
    super.key,
    this.intensity = MicroDetailTokens.cardSweepIntensity,
    this.seed = 0,
  });

  final double intensity;
  final int seed;

  @override
  State<HomeLivingSweep> createState() => _HomeLivingSweepState();
}

class _HomeLivingSweepState extends State<HomeLivingSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cycle;

  static const _active = 0.14;

  @override
  void initState() {
    super.initState();
    _cycle = AnimationController(
      vsync: this,
      duration: MicroDetailTokens.sweepDurationFor(widget.seed),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyQuietMotion.ambient(context, _cycle, rest: 0.5);
  }

  @override
  void dispose() {
    _cycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (OraclyQuietMotion.still(context)) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _cycle,
        builder: (context, _) {
          final v = _cycle.value;
          if (v > _active) return const SizedBox.shrink();
          return CustomPaint(
            painter: CardMicroSweepPainter(
              sweepPhase: (v / _active).clamp(0.0, 1.0),
              intensity: widget.intensity,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}
