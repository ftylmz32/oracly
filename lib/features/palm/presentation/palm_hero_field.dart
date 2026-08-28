/// Soft velvet / gold field behind the palm photo — never fake reading lines.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';
import 'palm_tokens.dart';

class PalmHeroField extends StatelessWidget {
  const PalmHeroField({super.key, required this.size, this.phase = 0});

  final double size;
  final double phase;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size(size, size),
        painter: _FieldPainter(phase: phase),
      ),
    );
  }
}

class _FieldPainter extends CustomPainter {
  const _FieldPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.52);
    final r = size.shortestSide * 0.48;
    final pulse = 0.88 + math.sin(phase * math.pi * 2) * 0.06;

    canvas.drawCircle(
      c,
      r * 1.12,
      Paint()
        ..color = const Color(0xFF1A0A2E).withValues(alpha: 0.52 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 34),
    );
    canvas.drawCircle(
      Offset(c.dx + r * 0.18, c.dy - r * 0.12),
      r * 0.78,
      Paint()
        ..color = PalmTokens.amberGlow.withValues(alpha: 0.10 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
    );
    canvas.drawCircle(
      c,
      r * 0.7,
      Paint()
        ..color = OraclyChrome.violet.withValues(alpha: 0.20 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    canvas.drawCircle(
      c,
      r * 0.9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.85
        ..color = OraclyChrome.gold.withValues(alpha: 0.16),
    );
  }

  @override
  bool shouldRepaint(covariant _FieldPainter old) => old.phase != phase;
}
