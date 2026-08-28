/// Coffee cup framing guide — interior ring, vignette, quiet ritual focus.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/oracly_quiet_motion.dart';
import '../../../core/theme/reading_typography.dart';
import 'coffee_cup_ring_painter.dart';

class CoffeeCupCaptureGuide extends StatefulWidget {
  const CoffeeCupCaptureGuide({
    super.key,
    this.tip,
    this.detail,
  });

  final String? tip;
  final String? detail;

  @override
  State<CoffeeCupCaptureGuide> createState() => _CoffeeCupCaptureGuideState();
}

class _CoffeeCupCaptureGuideState extends State<CoffeeCupCaptureGuide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyQuietMotion.ambient(context, _breath, rest: 0.18);
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _breath,
        builder: (context, _) {
          final pulse = OraclyQuietMotion.still(context)
              ? 0.18
              : 0.5 + math.sin(_breath.value * math.pi * 2) * 0.5;
          return CustomPaint(
            painter: CoffeeCupRingPainter(pulse: pulse),
            child: _GuideCopy(tip: widget.tip, detail: widget.detail),
          );
        },
      ),
    );
  }
}

class _GuideCopy extends StatelessWidget {
  const _GuideCopy({this.tip, this.detail});

  final String? tip;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    if (tip == null && detail == null) return const SizedBox.expand();
    return Align(
      alignment: const Alignment(0, 0.74),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tip != null)
              Text(
                tip!,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ReadingTypography.secondary(
                  color: OraclyChrome.cream.withValues(alpha: 0.90),
                ),
              ),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(
                detail!,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ReadingTypography.footnote(
                  color: OraclyChrome.goldLight.withValues(alpha: 0.78),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
