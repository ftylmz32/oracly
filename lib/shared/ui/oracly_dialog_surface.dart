/// Shared Oracly dialog surface for showGeneralDialog.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/design_system/app_shadows.dart';
import '../../core/navigation/immersive/immersive_motion.dart';
import '../../core/navigation/immersive/immersive_transition.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

Future<T?> showOraclyDialogSurface<T>(
  BuildContext context, {
  required Widget child,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: AppColors.black.withValues(
      alpha: ImmersiveMotion.overlayBarrierOpacity,
    ),
    transitionDuration: ImmersiveMotion.overlayEnter,
    pageBuilder: (context, animation, secondaryAnimation) {
      final media = MediaQuery.of(context);
      final keyboard = media.viewInsets.bottom;
      final maxHeight = (media.size.height -
              keyboard -
              media.padding.vertical -
              AppSpacing.xl)
          .clamp(220.0, media.size.height);
      return AnimatedPadding(
        padding: EdgeInsets.only(bottom: keyboard),
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Center(
          child: Padding(
            padding: AppSpacing.screenHorizontal,
            child: Material(
              color: Colors.transparent,
              borderRadius: AppRadius.lg,
              clipBehavior: Clip.antiAlias,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.surfaceElevated.withValues(alpha: 0.96),
                        AppColors.surface.withValues(alpha: 0.92),
                      ],
                    ),
                    borderRadius: AppRadius.lg,
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.28),
                    ),
                    boxShadow: AppShadows.luxury,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxHeight),
                    child: SingleChildScrollView(child: child),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return ImmersiveOverlayTransition(animation: animation, child: child);
    },
  );
}
