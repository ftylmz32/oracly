/// Gold zodiac glyph for a selector chip (linework, not Unicode).
library;

import 'package:flutter/material.dart';

import 'astrology_sign_glyphs.dart';

class AstrologyReferenceZodiacGlyph extends StatelessWidget {
  const AstrologyReferenceZodiacGlyph({
    super.key,
    required this.signId,
    required this.size,
    required this.alpha,
  });

  final String signId;
  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    final s = size;
    return SizedBox(
      width: s,
      height: s,
      child: CustomPaint(
        painter: _GlyphPainter(signId: signId, alpha: alpha),
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter({required this.signId, required this.alpha});

  final String signId;
  final double alpha;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    AstrologySignGlyphs.paint(
      canvas,
      signId,
      center,
      size.shortestSide * 0.46,
      alpha: alpha,
    );
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter oldDelegate) =>
      oldDelegate.signId != signId || oldDelegate.alpha != alpha;
}

