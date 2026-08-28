/// Bottom nav chrome — glass depth + active pill.
library;

import 'package:flutter/material.dart';

import '../../core/design_system/oracly_art_direction.dart';
import '../../core/design_system/oracly_chrome.dart';
import '../../core/design_system/oracly_surface_style.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';

abstract final class OraclyBottomBarChrome {
  OraclyBottomBarChrome._();

  static BoxDecoration bar(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final goldRim = OraclyArtDirection.clampGoldGlow(isLight ? 0.18 : 0.14);
    return BoxDecoration(
      borderRadius: OraclyChrome.navRadius,
      gradient: OraclySurfaceStyle.navBarFillOf(brightness),
      border: Border.all(
        color: AppColors.gold.withValues(alpha: isLight ? 0.48 : 0.40),
        width: 0.85,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.nearBlack.withValues(alpha: isLight ? 0.14 : 0.56),
          blurRadius: 24,
          offset: const Offset(0, 10),
          spreadRadius: -2,
        ),
        BoxShadow(
          color: AppColors.glowPurple.withValues(alpha: isLight ? 0.04 : 0.10),
          blurRadius: 18,
          spreadRadius: -4,
        ),
        BoxShadow(
          color: AppColors.glowGold.withValues(alpha: goldRim),
          blurRadius: 16,
          spreadRadius: -3,
        ),
      ],
    );
  }
}

class OraclyBottomNavActivePill extends StatelessWidget {
  const OraclyBottomNavActivePill({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.round,
        border: Border.all(
          color: AppColors.goldLight.withValues(alpha: 0.28),
          width: 0.6,
        ),
        gradient: RadialGradient(
          center: const Alignment(0, -0.35),
          radius: 0.95,
          colors: [
            AppColors.gold.withValues(alpha: 0.20),
            AppColors.purpleDark.withValues(alpha: 0.28),
            AppColors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.glowGold.withValues(alpha: 0.12),
            blurRadius: 10,
            spreadRadius: -2,
          ),
        ],
      ),
    );
  }
}
