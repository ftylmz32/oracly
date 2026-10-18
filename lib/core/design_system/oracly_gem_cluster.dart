/// Separated gems for the live economy rows. Counts stay 1–3.
library;

import 'package:flutter/material.dart';

import 'oracly_gem_icon.dart';

/// Small, medium, and large compositions of the same crystal.
class OraclyGemCluster extends StatelessWidget {
  const OraclyGemCluster({
    super.key,
    this.count = 1,
    this.size = 26,
    this.glow = 1,
    this.dimmed = false,
  });

  final int count;
  final double size;
  final double glow;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final stones = count.clamp(1, 3);
    if (stones == 1) {
      return OraclyGemIcon(size: size, glow: glow, dimmed: dimmed);
    }
    final scales = stones == 2 ? const [0.78, 0.92] : const [0.7, 0.86, 0.7];
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < scales.length; i++) ...[
          if (i > 0) const SizedBox(width: 3),
          OraclyGemIcon(size: size * scales[i], glow: glow, dimmed: dimmed),
        ],
      ],
    );
  }
}
