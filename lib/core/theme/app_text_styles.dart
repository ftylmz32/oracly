import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();


  // 🔮 Oracly Logo

  static const TextStyle logo = TextStyle(
    fontSize: 42,
    fontWeight: FontWeight.w900,
    color: AppColors.goldLight,
    letterSpacing: 4,
  );


  // 🌌 Büyük başlık

  static const TextStyle hero = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    color: AppColors.white,
    letterSpacing: .3,
  );


  // Kart başlıkları

  static const TextStyle heading = TextStyle(
    fontSize: 23,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
    letterSpacing: .2,
  );


  static const TextStyle title = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
  );


  // Açıklama yazıları

  static const TextStyle subtitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.6,
  );


  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.white,
    height: 1.6,
  );


  static const TextStyle bodyBold = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
  );


  // Küçük bilgiler

  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );


  // Butonlar

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
    letterSpacing: .8,
  );


  static const TextStyle small = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );
}