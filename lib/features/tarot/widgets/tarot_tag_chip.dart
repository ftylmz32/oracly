import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'tarot_typography.dart';

class TarotTagChip extends StatelessWidget {
  const TarotTagChip({super.key, required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  static const _palette = [
    Color(0xFF8B5CF6),
    Color(0xFFE879A9),
    Color(0xFF60A5FA),
    Color(0xFF34D399),
  ];

  static Color colorAt(int index) => _palette[index % _palette.length];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color.withValues(alpha: 0.9)),
            const SizedBox(width: 4),
          ],
          Text(label, style: TarotTypography.captionMuted(size: 10.5).copyWith(color: color.withValues(alpha: 0.95))),
        ],
      ),
    );
  }
}

class TarotSpreadCountPill extends StatelessWidget {
  const TarotSpreadCountPill({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count == 1 ? '1 Kart' : '$count Kart';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.55)),
        color: AppColors.gold.withValues(alpha: 0.08),
      ),
      child: Text(label, style: TarotTypography.spreadTitle(selected: true).copyWith(fontSize: 11)),
    );
  }
}
