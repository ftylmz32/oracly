/// OR-1000 — Tarot loading state component.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/chamber_waiting_orb.dart';

/// Premium loading indicator for async tarot operations.
class TarotLoading extends StatelessWidget {
  const TarotLoading({
    super.key,
    this.message = 'Evren dinleniyor...',
    this.seed = 0,
  });

  final String message;
  final int seed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: message,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ChamberWaitingOrb(size: AppSpacing.xxl, seed: seed),
            SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
