import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/glass_card.dart';

class GreetingSection extends StatefulWidget {
  const GreetingSection({
    super.key,
    required this.greeting,
    required this.message,
  });

  final String greeting;
  final String message;

  @override
  State<GreetingSection> createState() => _GreetingSectionState();
}

class _GreetingSectionState extends State<GreetingSection> {
  IconData _iconFromGreeting() {
    if (widget.greeting.contains('Günaydın')) {
      return Icons.wb_sunny_rounded;
    }
    if (widget.greeting.contains('Tünaydın')) {
      return Icons.wb_cloudy_rounded;
    }
    if (widget.greeting.contains('İyi Akşamlar')) {
      return Icons.nights_stay_rounded;
    }
    return Icons.auto_awesome_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 620),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 0.985 + (0.015 * value),
              child: child,
            ),
          ),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 24,
            right: 24,
            top: 18,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: 40,
                  sigmaY: 40,
                ),
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.xl,
                    color: AppColors.gold.withValues(alpha: .08),
                  ),
                ),
              ),
            ),
          ),
          GlassCard(
            padding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 24,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: .1),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: .18),
                    ),
                    boxShadow: AppShadows.soft,
                  ),
                  child: Icon(
                    _iconFromGreeting(),
                    color: AppColors.gold.withValues(alpha: .85),
                    size: 30,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.greeting,
                        style: AppTextStyles.hero.copyWith(
                          fontSize: 26,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        widget.message,
                        style: AppTextStyles.subtitle.copyWith(
                          height: 1.65,
                          color: AppColors.textSecondary.withValues(
                            alpha: .88,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
