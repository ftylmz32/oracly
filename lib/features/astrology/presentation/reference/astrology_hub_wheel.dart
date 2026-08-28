/// Celestial hero — ornate observatory wheel + selected sign portal.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_motion.dart';
import '../../../../core/theme/oracly_quiet_motion.dart';
import '../../../content/astrology/models/astrology_content.dart';
import 'astrology_hub_wheel_plate.dart';
import 'astrology_supported_sky.dart';

class AstrologyHubWheel extends StatefulWidget {
  const AstrologyHubWheel({
    super.key,
    required this.sign,
    required this.side,
    this.sky,
  });

  final ZodiacSignContent sign;
  final double side;

  /// Defaults to tropical Sun only — never invents Moon/planets.
  final AstrologySupportedSky? sky;

  @override
  State<AstrologyHubWheel> createState() => _AstrologyHubWheelState();
}

class _AstrologyHubWheelState extends State<AstrologyHubWheel>
    with TickerProviderStateMixin {
  late final AnimationController _breath;
  late final AnimationController _settle;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 11200),
    );
    _settle = AnimationController(
      vsync: this,
      duration: AppMotionDuration.slow,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyQuietMotion.ambient(context, _breath, reverse: true, rest: 0.4);
  }

  @override
  void didUpdateWidget(covariant AstrologyHubWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sign.id == widget.sign.id) return;
    if (OraclyQuietMotion.still(context)) return;
    _settle.forward(from: 0);
  }

  @override
  void dispose() {
    _breath.dispose();
    _settle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = math.max(200.0, widget.side);
    final plate = s * 0.96;
    final portal = plate * 0.42;
    final supported =
        widget.sky ?? AstrologySupportedSky(sunSignId: widget.sign.id);
    final still = OraclyQuietMotion.still(context);

    Widget body(double phase, double settle) {
      // Slow celestial settle — a few degrees, then rest.
      final drift = still ? 0.0 : math.sin(settle * math.pi) * 0.018;
      return Transform.rotate(
        angle: drift,
        child: AstrologyHubWheelPlate(
          signId: widget.sign.id,
          plate: plate,
          portal: portal,
          sky: supported,
          phase: phase,
        ),
      );
    }

    return SizedBox(
      width: s,
      height: s,
      child: still
          ? body(0.4, 0)
          : AnimatedBuilder(
              animation: Listenable.merge([_breath, _settle]),
              builder: (context, _) => body(_breath.value, _settle.value),
            ),
    );
  }
}
