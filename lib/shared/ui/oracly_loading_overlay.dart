/// OR-1120 — Full-screen loading overlay.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../widgets/chamber_waiting_orb.dart';

abstract final class OraclyLoadingOverlay {
  OraclyLoadingOverlay._();

  static OverlayEntry? _entry;

  static void show(
    BuildContext context, {
    String message = 'Evren dinleniyor...',
  }) {
    hide();
    final overlay = Overlay.of(context);
    _entry = OverlayEntry(
      builder: (context) => Material(
        color: AppColors.background.withValues(alpha: 0.55),
        child: Stack(
          fit: StackFit.expand,
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: const SizedBox.expand(),
            ),
            Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated.withValues(alpha: 0.94),
                  borderRadius: AppRadius.lg,
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.28),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ChamberWaitingOrb(size: 28, seed: 2),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      message,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    overlay.insert(_entry!);
  }

  static void hide() {
    _entry?.remove();
    _entry = null;
  }
}
