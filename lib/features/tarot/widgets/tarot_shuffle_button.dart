/// OR-1021 — Cinematic premium shuffle CTA.
library;

import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/oracly_brand_signature.dart';
import '../../../shared/widgets/oracly_pressable.dart';

/// Large gold ritual button — breathing glow, ripple, luxury shadow.
class TarotShuffleButton extends StatefulWidget {
  const TarotShuffleButton({
    super.key,
    this.onPressed,
    this.label = 'Kartları Karıştır',
  });

  final VoidCallback? onPressed;
  final String label;

  @override
  State<TarotShuffleButton> createState() => _TarotShuffleButtonState();
}

class _TarotShuffleButtonState extends State<TarotShuffleButton>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _breath;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat(reverse: true);
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _breath]),
      builder: (context, child) {
        final glow = 0.5 + sin(_pulse.value * pi) * 0.5;
        final breathScale = 1 + (_breath.value - 0.5) * 0.008;
        return Transform.scale(
          scale: breathScale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.lg,
              boxShadow: [
                BoxShadow(
                  color: AppColors.goldGlow.withValues(alpha: 0.24 + glow * 0.20),
                  blurRadius: 24 + glow * 12,
                  spreadRadius: 1 + glow * 2.5,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: AppColors.glowPurple.withValues(alpha: 0.14 + glow * 0.12),
                  blurRadius: 38 + glow * 10,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: OraclyPressable(
        onTap: widget.onPressed,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        scale: false,
        opacity: false,
        depth: false,
        child: AnimatedScale(
          scale: _pressed ? OraclySignatureMotion.pressScale : 1,
          duration: _pressed
              ? OraclySignatureMotion.press
              : OraclySignatureMotion.pressRelease,
          curve: _pressed
              ? OraclySignatureMotion.curve
              : OraclySignatureMotion.releaseCurve,
          child: ClipRRect(
            borderRadius: AppRadius.lg,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: widget.onPressed,
                splashColor: AppColors.goldLight.withValues(alpha: 0.32),
                highlightColor: AppColors.gold.withValues(alpha: 0.16),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFF5E6A8),
                        Color(0xFFD4AF37),
                        Color(0xFFC9A227),
                        Color(0xFFB8941F),
                      ],
                      stops: [0.0, 0.35, 0.72, 1.0],
                    ),
                    borderRadius: AppRadius.lg,
                    border: Border.all(
                      color: AppColors.goldLight.withValues(alpha: 0.62),
                      width: AppBorderWidth.hairline,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        height: 1.5,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.white.withValues(alpha: 0.45),
                                AppColors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: AppSpacing.xxl + AppSpacing.sm,
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_fix_high_rounded,
                                size: AppSpacing.md,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: AppSpacing.sm),
                              Text(
                                widget.label,
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
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
    );
  }
}
