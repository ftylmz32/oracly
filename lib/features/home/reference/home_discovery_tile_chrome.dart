/// Discovery tile chrome — identity glyph + enter mark.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class HomeDiscoveryIdentityIcon extends StatelessWidget {
  const HomeDiscoveryIdentityIcon({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.nearBlack.withValues(alpha: 0.32),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.62),
          width: 0.85,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.glowGold.withValues(alpha: 0.12),
            blurRadius: 8,
          ),
        ],
      ),
      child: SizedBox(
        width: 24,
        height: 24,
        child: Icon(
          icon,
          size: 13,
          color: AppColors.goldLight.withValues(alpha: 0.94),
        ),
      ),
    );
  }
}

class HomeDiscoveryEnterMark extends StatelessWidget {
  const HomeDiscoveryEnterMark({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.goldLight.withValues(alpha: 0.62),
          width: 0.95,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceElevated.withValues(alpha: 0.55),
            AppColors.nearBlack.withValues(alpha: 0.55),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.glowGold.withValues(alpha: 0.10),
            blurRadius: 6,
          ),
        ],
      ),
      child: SizedBox(
        width: 22,
        height: 22,
        child: Icon(
          Icons.arrow_forward_rounded,
          size: 12,
          color: AppColors.goldLight.withValues(alpha: 0.95),
        ),
      ),
    );
  }
}

/// Quiet chip for newly added discovery doors.
class HomeDiscoveryNewBadge extends StatelessWidget {
  const HomeDiscoveryNewBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppColors.primaryPurple.withValues(alpha: 0.55),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          label,
          style: TextStyle(
            color: AppColors.goldLight.withValues(alpha: 0.95),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}
