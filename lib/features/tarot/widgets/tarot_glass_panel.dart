import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/design_system/app_gradients.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import 'tarot_typography.dart';

/// Single glass interpretation section panel.
class TarotGlassPanel extends StatelessWidget {
  const TarotGlassPanel({
    super.key,
    required this.title,
    required this.body,
    required this.icon,
    this.delayMs = 0,
  });

  final String title;
  final String body;
  final IconData icon;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 520 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, (1 - v) * 12),
          child: child,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppGradients.glass,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.22),
              ),
              boxShadow: AppShadows.soft,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 16, color: AppColors.goldLight),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: TarotTypography.sectionGold(size: 14.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 0.6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.gold.withValues(alpha: 0.45),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(body, style: TarotTypography.body(size: 14)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
