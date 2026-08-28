/// Candle dust behind the archive plate — never an observatory starfield.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/oracly_quiet_motion.dart';
import 'star_map_reference_tokens.dart';

class StarMapStarDrift extends StatefulWidget {
  const StarMapStarDrift({super.key, required this.child});

  final Widget child;

  @override
  State<StarMapStarDrift> createState() => _StarMapStarDriftState();
}

class _StarMapStarDriftState extends State<StarMapStarDrift>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 42),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      OraclyQuietMotion.ambient(context, _drift, rest: 0);
    });
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _drift,
      builder: (context, child) {
        final still = OraclyQuietMotion.still(context);
        final t = still ? 0.0 : _drift.value;
        return CustomPaint(
          isComplex: true,
          willChange: TickerMode.valuesOf(context).enabled && !still,
          painter: _CandleDustPainter(
            phase: t,
            count: OraclyQuietMotion.constrained(context) ? 6 : 12,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _CandleDustPainter extends CustomPainter {
  const _CandleDustPainter({required this.phase, this.count = 12});

  final double phase;
  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    final brass = StarMapReferenceTokens.brassGlow;
    final candle = StarMapReferenceTokens.candleAmber;
    for (var i = 0; i < count; i++) {
      final dx = size.width * ((0.12 + i * 0.071 + phase * 0.05) % 1.0);
      final dy = size.height * ((0.16 + i * 0.053 + phase * 0.03) % 1.0);
      final warm = i.isEven ? candle : brass;
      canvas.drawCircle(
        Offset(dx, dy),
        i % 3 == 0 ? 1.2 : 0.65,
        Paint()..color = warm.withValues(alpha: 0.10 + (i % 4) * 0.03),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CandleDustPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.count != count;
}
