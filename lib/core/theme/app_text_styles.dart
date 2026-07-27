import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle logo = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: AppColors.gold,
    letterSpacing: 2,
  );

  static const TextStyle heading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: AppColors.white,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );
}