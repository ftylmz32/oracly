/// Soft amber halo around the ORACLY mark — warning without aggressive red.
library;

import 'package:flutter/material.dart';

import '../../core/brand/oracly_brand_mark.dart';
import '../../core/design_system/oracly_chrome.dart';

class OraclyErrorEmblem extends StatelessWidget {
  const OraclyErrorEmblem({super.key, this.size = 72});

  final double size;

  static const Color amber = Color(0xFFC9A46C);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              amber.withValues(alpha: 0.28),
              OraclyChrome.midnight.withValues(alpha: 0.0),
            ],
          ),
          border: Border.all(
            color: amber.withValues(alpha: 0.42),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: amber.withValues(alpha: 0.18),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: OraclyBrandMark(size: size * 0.58),
        ),
      ),
    );
  }
}
