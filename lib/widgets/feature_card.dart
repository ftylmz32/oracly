import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_decorations.dart';
import '../core/theme/app_shadows.dart';
import '../core/theme/app_text_styles.dart';
import '../shared/widgets/oracly_pressable.dart';
import 'oracly_icon.dart';

class FeatureCard extends StatefulWidget {
  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  State<FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<FeatureCard> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: OraclyPressable(
        onTap: widget.onTap,
        child: Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.glass,
              gradient: AppGradients.glass,
              border: Border.all(color: AppColors.glassBorder),
              boxShadow: AppShadows.card,
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: AppColors.card,
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
                      boxShadow: AppShadows.iconGlow,
                    ),
                    child: Center(child: OraclyIcon(widget.icon, size: 24)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: AppTextStyles.title),
                        const SizedBox(height: 4),
                        Text(widget.subtitle, style: AppTextStyles.subtitle.copyWith(fontSize: 14)),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
      ),
    );
  }
}
