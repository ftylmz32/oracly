/// Subtle celestial dust for memory chambers — never a busy sky.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/oracly_quiet_motion.dart';

class DiscoveryArchiveMotifs extends StatefulWidget {
  const DiscoveryArchiveMotifs({super.key});

  @override
  State<DiscoveryArchiveMotifs> createState() => _DiscoveryArchiveMotifsState();
}

class _DiscoveryArchiveMotifsState extends State<DiscoveryArchiveMotifs>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 48),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyQuietMotion.ambient(context, _drift, rest: 0.2);
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _drift,
        builder: (context, _) {
          final still = OraclyQuietMotion.still(context);
          return CustomPaint(
            painter: _ArchiveMotifPainter(
              phase: still ? 0.2 : _drift.value,
              sparse: OraclyQuietMotion.constrained(context),
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _ArchiveMotifPainter extends CustomPainter {
  const _ArchiveMotifPainter({required this.phase, required this.sparse});

  final double phase;
  final bool sparse;

  @override
  void paint(Canvas canvas, Size size) {
    final gold = OraclyChrome.goldLight;
    final count = sparse ? 9 : 16;
    for (var i = 0; i < count; i++) {
      final t = (i * 0.137 + phase * 0.04) % 1.0;
      final x = size.width * ((0.08 + i * 0.061 + phase * 0.02) % 1.0);
      final y = size.height * ((0.10 + i * 0.055 + t * 0.03) % 1.0);
      final a = 0.06 + (i % 4) * 0.025;
      canvas.drawCircle(
        Offset(x, y),
        i.isEven ? 1.05 : 0.55,
        Paint()..color = gold.withValues(alpha: a),
      );
    }
    // Quiet constellation fragment — three linked points, not a zodiac ring.
    final cx = size.width * 0.78;
    final cy = size.height * 0.18;
    final pts = [
      Offset(cx, cy),
      Offset(cx + 18, cy + 10),
      Offset(cx + 8, cy + 26),
    ];
    final line = Paint()
      ..color = gold.withValues(alpha: 0.10)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;
    canvas.drawLine(pts[0], pts[1], line);
    canvas.drawLine(pts[1], pts[2], line);
    for (final p in pts) {
      canvas.drawCircle(
        p,
        1.2,
        Paint()..color = gold.withValues(alpha: 0.18),
      );
    }
    // Soft warm archive glow (candle, not instrument).
    canvas.drawCircle(
      Offset(size.width * 0.22, size.height * 0.12),
      size.shortestSide * 0.28,
      Paint()
        ..color = const Color(0xFFC4A574).withValues(alpha: 0.05)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
    );
  }

  @override
  bool shouldRepaint(covariant _ArchiveMotifPainter old) =>
      old.phase != phase || old.sparse != sparse;
}
