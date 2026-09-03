/// Canonical Oracly gem — violet jewel with gold rim, any size.
library;

import 'package:flutter/material.dart';

import 'oracly_gem_icon_painter.dart';

/// Live gem identity — use everywhere mücevher appears.
class OraclyGemIcon extends StatelessWidget {
  const OraclyGemIcon({
    super.key,
    this.size = 28,
    this.glow = 1,
    this.dimmed = false,
    this.semanticsLabel,
  });

  final double size;
  final double glow;
  final bool dimmed;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      image: semanticsLabel != null,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: OraclyGemIconPainter(glow: glow, dimmed: dimmed),
        ),
      ),
    );
  }
}
