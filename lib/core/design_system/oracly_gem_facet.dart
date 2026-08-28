/// Photoreal gem facet — delegates to canonical [OraclyGemIcon].
library;

import 'package:flutter/material.dart';

import 'oracly_gem_icon.dart';

/// Shared gem chrome for capsules, economy rows, and balance plates.
class OraclyGemFacet extends StatelessWidget {
  const OraclyGemFacet({
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
    return OraclyGemIcon(
      size: size,
      glow: glow,
      dimmed: dimmed,
      semanticsLabel: semanticsLabel,
    );
  }
}
