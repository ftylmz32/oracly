/// OR-1120 / EPIC-025 — Consistent modal bottom sheets with luxury motion.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/design_system/app_shadows.dart';
import '../../core/navigation/immersive/immersive_motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

abstract final class OraclyBottomSheet {
  OraclyBottomSheet._();

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget child,
    bool isDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: isDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: AppColors.black.withValues(
        alpha: ImmersiveMotion.overlayBarrierOpacity,
      ),
      transitionDuration: ImmersiveMotion.overlayEnter,
      pageBuilder: (context, animation, secondaryAnimation) {
        final media = MediaQuery.of(context);
        final maxHeight = (media.size.height * 0.88) - media.viewInsets.bottom;
        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: maxHeight.clamp(240.0, media.size.height),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xlValue),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.surfaceElevated.withValues(alpha: 0.96),
                          AppColors.surface.withValues(alpha: 0.94),
                        ],
                      ),
                      border: Border(
                        top: BorderSide(
                          color: AppColors.gold.withValues(alpha: 0.28),
                        ),
                      ),
                      boxShadow: AppShadows.luxury,
                    ),
                    child: SafeArea(
                      top: false,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: AppSpacing.sm),
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.gold.withValues(alpha: 0.35),
                                  borderRadius: AppRadius.round,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(AppSpacing.md),
                              child: Text(
                                title,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: AppColors.goldLight,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            child,
                            SizedBox(height: AppSpacing.md),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: ImmersiveMotion.pageEnterCurve,
          reverseCurve: ImmersiveMotion.pageExitCurve,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(
                begin: ImmersiveMotion.overlayScaleBegin,
                end: 1,
              ).animate(curved),
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
