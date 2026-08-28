/// Selected / press shadows - natural table cast, not a neon lift.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../deck/tarot_contact_shadow.dart';

List<BoxShadow> cardSelectionShadows({
  required double touch,
  required bool selected,
}) {
  if (selected) {
    return [
      ...tarotContactShadow(elevation: 0.88, goldWhisper: 0.42),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.22),
        blurRadius: 20,
        offset: const Offset(0, 16),
        spreadRadius: -5,
      ),
    ];
  }

  final pressed = Curves.easeOutCubic.transform(touch.clamp(0.0, 1.0));
  return [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.36 + pressed * 0.16),
      blurRadius: 8 + pressed * 10,
      offset: Offset(0, 3 + pressed * 8),
      spreadRadius: -2,
    ),
    BoxShadow(
      color: const Color(0xFF1A0A10).withValues(alpha: 0.24),
      blurRadius: 14 + pressed * 5,
      offset: Offset(0, 7 + pressed * 3),
      spreadRadius: -3,
    ),
    BoxShadow(
      color: AppColors.goldLight.withValues(alpha: 0.03 + pressed * 0.10),
      blurRadius: 10 + pressed * 5,
      offset: Offset(0, 2 + pressed * 2),
    ),
  ];
}
