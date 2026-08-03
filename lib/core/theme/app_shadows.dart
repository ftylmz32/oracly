import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppShadows {
  AppShadows._();

  static final List<BoxShadow> soft = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.18),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];

  static final List<BoxShadow> glass = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.25),
      blurRadius: 30,
      offset: const Offset(0, 12),
    ),
  ];

  static final List<BoxShadow> goldGlow = [
    BoxShadow(
      color: AppColors.goldGlow,
      blurRadius: 28,
      spreadRadius: 2,
    ),
  ];
}
