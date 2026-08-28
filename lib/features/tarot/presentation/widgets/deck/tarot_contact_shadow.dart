/// Soft contact shadow oval — table contact, candle-warm gold whisper.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/oracly_brand_signature.dart';

List<BoxShadow> tarotContactShadow({
  required double elevation,
  double goldWhisper = 0.55,
}) {
  final lift = elevation.clamp(0.0, 1.0);
  final gold = goldWhisper.clamp(0.0, 1.0);
  return [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.42 + lift * 0.18),
      blurRadius: 7 + lift * 11,
      offset: Offset(0, 2.6 + lift * 5.2),
      spreadRadius: -2.2,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.28),
      blurRadius: 2.4 + lift * 1.2,
      offset: Offset(0, 1.1 + lift * 0.9),
      spreadRadius: -2.8,
    ),
    BoxShadow(
      color: const Color(0xFF1A0A10).withValues(alpha: 0.35 + lift * 0.12),
      blurRadius: 14 + lift * 8,
      offset: Offset(0, 6 + lift * 3),
      spreadRadius: -4,
    ),
    if (gold > 0.01)
      BoxShadow(
        color: OraclySignaturePalette.champagne.withValues(
          alpha: 0.07 * gold + lift * 0.03,
        ),
        blurRadius: 10 + lift * 4,
        offset: const Offset(0, 2),
      ),
    if (gold > 0.2)
      BoxShadow(
        color: const Color(0xFFE8C872).withValues(alpha: 0.04 * gold),
        blurRadius: 16,
        offset: const Offset(-2, 1),
      ),
  ];
}
