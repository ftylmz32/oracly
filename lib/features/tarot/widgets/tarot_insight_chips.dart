import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../utils/tarot_reading_parser.dart';
import 'tarot_typography.dart';

/// Premium Energy · Theme · Guidance chips for the reading screen.
class TarotInsightChips extends StatelessWidget {
  const TarotInsightChips({super.key, required this.insights});

  final TarotReadingInsights insights;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        TarotPremiumChip(
          label: insights.energy,
          caption: 'Enerji',
          icon: Icons.bolt_rounded,
          accent: AppColors.gold,
        ),
        TarotPremiumChip(
          label: insights.theme,
          caption: 'Tema',
          icon: Icons.auto_awesome_rounded,
          accent: AppColors.primaryLight,
        ),
        TarotPremiumChip(
          label: insights.guidance,
          caption: 'Rehberlik',
          icon: Icons.explore_rounded,
          accent: AppColors.goldLight,
        ),
      ],
    );
  }
}

class TarotPremiumChip extends StatelessWidget {
  const TarotPremiumChip({
    super.key,
    required this.label,
    required this.caption,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String caption;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.card.withValues(alpha: 0.92),
            AppColors.surface.withValues(alpha: 0.85),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.42)),
        boxShadow: [
          ...AppShadows.soft,
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 14,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.14),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, size: 14, color: accent),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                caption.toUpperCase(),
                style: TarotTypography.captionMuted(size: 9),
              ),
              Text(
                label,
                style: TarotTypography.body(size: 12.5).copyWith(
                  color: AppColors.goldLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
