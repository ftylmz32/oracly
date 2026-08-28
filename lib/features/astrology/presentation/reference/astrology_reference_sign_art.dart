/// Selected-sign illustrated emblem — unique character, shared celestial DNA.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/oracly_quiet_motion.dart';
import 'astrology_sign_light_sweep.dart';
import 'astrology_zodiac_illustration.dart';

class AstrologyReferenceSignArt extends StatefulWidget {
  const AstrologyReferenceSignArt({
    super.key,
    required this.signId,
    this.size = 112,
  });

  final String signId;
  final double size;

  @override
  State<AstrologyReferenceSignArt> createState() =>
      _AstrologyReferenceSignArtState();
}

class _AstrologyReferenceSignArtState extends State<AstrologyReferenceSignArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyQuietMotion.ambient(context, _breath, reverse: true, rest: 0.4);
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = OraclyQuietMotion.still(context);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: still
          ? _SignPlate(signId: widget.signId, t: 0.4)
          : AnimatedBuilder(
              animation: _breath,
              builder: (context, _) => _SignPlate(
                signId: widget.signId,
                t: _breath.value,
              ),
            ),
    );
  }
}

class _SignPlate extends StatelessWidget {
  const _SignPlate({required this.signId, required this.t});

  final String signId;
  final double t;

  @override
  Widget build(BuildContext context) {
    final pulse = 0.08 + math.sin(t * math.pi * 2).abs() * 0.06;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: OraclyChrome.gold.withValues(alpha: 0.14 + pulse),
            blurRadius: 18,
          ),
          BoxShadow(
            color: OraclyChrome.violet.withValues(alpha: 0.16 + pulse * 0.5),
            blurRadius: 26,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: OraclyChrome.midnight),
            AstrologyZodiacIllustration(signId: signId),
            AstrologySignLightSweep(signId: signId),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.2, -0.35),
                    radius: 1.05,
                    colors: [
                      OraclyChrome.gold.withValues(alpha: 0.10 + pulse * 0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: OraclyChrome.goldLight.withValues(alpha: 0.42),
                    width: 1.1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
