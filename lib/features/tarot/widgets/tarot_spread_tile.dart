/// OR-030 / OR-1021 — Cinematic premium spread selection tile.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/oracly_brand_signature.dart';

/// Frosted glass spread tile — luxury press and purple energy when selected.
class TarotSpreadTile extends StatefulWidget {
  const TarotSpreadTile({
    super.key,
    required this.title,
    required this.icon,
    this.selected = false,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final bool selected;

  @override
  State<TarotSpreadTile> createState() => _TarotSpreadTileState();
}

class _TarotSpreadTileState extends State<TarotSpreadTile> {
  bool _pressed = false;

  Duration get _duration => _pressed
      ? OraclySignatureMotion.press
      : OraclySignatureMotion.pressRelease;

  Curve get _curve => _pressed
      ? OraclySignatureMotion.curve
      : OraclySignatureMotion.releaseCurve;

  @override
  Widget build(BuildContext context) {
    final active = widget.selected;
    final pressed = _pressed && !active;

    return GestureDetector(
      onTapDown: active ? null : (_) => setState(() => _pressed = true),
      onTapUp: active ? null : (_) => setState(() => _pressed = false),
      onTapCancel: active ? null : () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        opacity: pressed ? OraclySignatureMotion.pressOpacity : 1,
        duration: _duration,
        curve: _curve,
        child: AnimatedScale(
          scale: pressed ? OraclySignatureMotion.pressScale : 1,
          duration: _duration,
          curve: _curve,
          child: AnimatedContainer(
            duration: _duration,
            curve: _curve,
            transform: Matrix4.translationValues(
              0,
              pressed ? OraclySignatureMotion.pressDepth : 0,
              0,
            ),
            child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.md,
            boxShadow: active
                ? [
                    ...AppShadows.soft,
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.38),
                      blurRadius: AppShadowMetrics.goldBlur + 6,
                      spreadRadius: AppShadowMetrics.goldSpread + 1,
                    ),
                    BoxShadow(
                      color: AppColors.glowPurple.withValues(alpha: 0.42),
                      blurRadius: AppShadowMetrics.cardGlowBlur + 4,
                    ),
                    BoxShadow(
                      color: AppColors.purpleGlow.withValues(alpha: 0.28),
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                  ]
                : pressed
                    ? [
                        ...AppShadows.soft,
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.18),
                          blurRadius: 14,
                        ),
                      ]
                    : AppShadows.soft,
          ),
          child: ClipRRect(
            borderRadius: AppRadius.md,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.surfaceElevated.withValues(alpha: active ? 0.97 : 0.88),
                      AppColors.surface.withValues(alpha: active ? 0.93 : 0.80),
                    ],
                  ),
                  borderRadius: AppRadius.md,
                  border: Border.all(
                    color: active
                        ? AppColors.gold.withValues(alpha: 0.82)
                        : AppColors.gold.withValues(alpha: 0.30),
                    width: active ? AppBorderWidth.thin : AppBorderWidth.hairline,
                  ),
                ),
                child: Stack(
                  children: [
                    if (active)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment.center,
                              radius: 1.1,
                              colors: [
                                AppColors.glowPurple.withValues(alpha: 0.22),
                                AppColors.purpleGlow.withValues(alpha: 0.10),
                                AppColors.transparent,
                              ],
                              stops: const [0.0, 0.45, 1.0],
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: 1.5,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.white.withValues(alpha: active ? 0.18 : 0.10),
                              AppColors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 28,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: active ? 0.22 : 0.16),
                              AppColors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.sm + AppSpacing.xs,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.purple.withValues(alpha: active ? 0.48 : 0.26),
                                  AppColors.purpleDark.withValues(alpha: active ? 0.62 : 0.36),
                                ],
                              ),
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: active ? 0.68 : 0.36),
                                width: AppBorderWidth.hairline,
                              ),
                              boxShadow: active
                                  ? [
                                      BoxShadow(
                                        color: AppColors.goldGlow.withValues(alpha: 0.42),
                                        blurRadius: AppSpacing.sm + 2,
                                      ),
                                      BoxShadow(
                                        color: AppColors.glowPurple.withValues(alpha: 0.30),
                                        blurRadius: AppSpacing.md,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: SizedBox(
                              width: AppSpacing.lg + AppSpacing.xs,
                              height: AppSpacing.lg + AppSpacing.xs,
                              child: Icon(
                                widget.icon,
                                size: AppSpacing.md,
                                color: active
                                    ? AppColors.goldLight
                                    : AppColors.gold.withValues(alpha: 0.78),
                              ),
                            ),
                          ),
                          SizedBox(height: AppSpacing.sm),
                          Text(
                            widget.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelLarge.copyWith(
                              fontSize: 13,
                              color: active ? AppColors.goldLight : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              height: 1.15,
                            ),
                          ),
                          if (widget.subtitle != null) ...[
                            SizedBox(height: AppSpacing.xs / 2),
                            Text(
                              widget.subtitle!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.textHint,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
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
  }
}
