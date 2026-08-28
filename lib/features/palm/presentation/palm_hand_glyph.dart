/// Quiet palm outline glyph — mirrored for left; never fake reading lines.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';

class PalmHandGlyph extends StatelessWidget {
  const PalmHandGlyph({
    super.key,
    required this.left,
    this.selected = false,
    this.size = 28,
  });

  final bool left;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final child = CustomPaint(
      size: Size(size, size * 1.15),
      painter: _GlyphPainter(selected: selected),
    );
    if (!left) return child;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.diagonal3Values(-1, 1, 1),
      child: child,
    );
  }
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter({required this.selected});

  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.50;
    final cy = size.height * 0.58;
    final w = size.width * 0.22;
    final palm = Path()
      ..moveTo(cx - w * 0.72, cy + w * 1.05)
      ..quadraticBezierTo(cx, cy + w * 1.22, cx + w * 0.72, cy + w * 1.05)
      ..lineTo(cx + w * 0.70, cy + w * 0.12)
      ..quadraticBezierTo(cx + w * 1.18, cy - w * 0.08, cx + w * 1.10, cy - w * 0.55)
      ..quadraticBezierTo(cx + w * 0.92, cy - w * 0.18, cx + w * 0.52, cy - w * 0.10)
      ..quadraticBezierTo(cx + w * 0.58, cy - w * 1.38, cx + w * 0.28, cy - w * 1.42)
      ..quadraticBezierTo(cx + w * 0.18, cy - w * 0.22, cx + w * 0.12, cy - w * 0.12)
      ..quadraticBezierTo(cx + w * 0.08, cy - w * 1.58, cx - w * 0.12, cy - w * 1.52)
      ..quadraticBezierTo(cx - w * 0.06, cy - w * 0.22, cx - w * 0.16, cy - w * 0.10)
      ..quadraticBezierTo(cx - w * 0.22, cy - w * 1.38, cx - w * 0.48, cy - w * 1.28)
      ..quadraticBezierTo(cx - w * 0.38, cy - w * 0.18, cx - w * 0.48, cy - w * 0.06)
      ..quadraticBezierTo(cx - w * 0.92, cy - w * 0.02, cx - w * 0.88, cy - w * 0.48)
      ..quadraticBezierTo(cx - w * 1.05, cy + w * 0.06, cx - w * 0.70, cy + w * 0.16)
      ..close();

    final gold = selected
        ? OraclyChrome.goldLight.withValues(alpha: 0.92)
        : OraclyChrome.gold.withValues(alpha: 0.42);
    canvas.drawPath(
      palm,
      Paint()
        ..color = OraclyChrome.violet.withValues(alpha: selected ? 0.28 : 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawPath(
      palm,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 1.35 : 1.05
        ..color = gold,
    );
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter old) => old.selected != selected;
}
