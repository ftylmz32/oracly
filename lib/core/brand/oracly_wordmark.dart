/// ORACLY wordmark — antique gold tracking, pairs with the official logo.
library;

import 'package:flutter/material.dart';

import '../theme/oracly_brand_signature.dart';

class OraclyWordmark extends StatelessWidget {
  const OraclyWordmark({
    super.key,
    this.size = 28,
    this.color,
  });

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      'ORACLY',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w500,
        letterSpacing: size * 0.22,
        height: 1.1,
        color: color ??
            OraclySignaturePalette.champagne.withValues(alpha: 0.94),
      ),
    );
  }
}
