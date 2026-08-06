/// OR-1100 — Luxury error card with retry animation.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/copy/resilience_copy.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class OraclyErrorState extends StatefulWidget {
  const OraclyErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.title = ResilienceCopy.errorTitle,
  });

  final String message;
  final VoidCallback? onRetry;
  final String title;

  @override
  State<OraclyErrorState> createState() => _OraclyErrorStateState();
}

class _OraclyErrorStateState extends State<OraclyErrorState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenHorizontal,
        child: ClipRRect(
          borderRadius: AppRadius.xl,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.surfaceElevated.withValues(alpha: 0.92),
                    AppColors.surface.withValues(alpha: 0.84),
                  ],
                ),
                borderRadius: AppRadius.xl,
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.35),
                  width: AppBorderWidth.hairline,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, _) {
                        return Icon(
                          Icons.error_outline_rounded,
                          size: AppSpacing.xxl + AppSpacing.sm,
                          color: AppColors.error.withValues(
                            alpha: 0.65 + _pulse.value * 0.35,
                          ),
                        );
                      },
                    ),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      widget.title,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.goldLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    if (widget.onRetry != null) ...[
                      SizedBox(height: AppSpacing.lg),
                      Semantics(
                        button: true,
                        label: ResilienceCopy.retryAction,
                        child: _RetryButton(onPressed: widget.onRetry!),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RetryButton extends StatelessWidget {
  const _RetryButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.lg,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadius.lg,
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.42),
              width: AppBorderWidth.hairline,
            ),
            color: AppColors.surface.withValues(alpha: 0.55),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm + 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh_rounded, color: AppColors.goldLight, size: 18),
                SizedBox(width: AppSpacing.sm),
                Text(
                  ResilienceCopy.retryAction,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.goldLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
