import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'tarot_typography.dart';

class TarotReadingChecklist extends StatelessWidget {
  const TarotReadingChecklist({super.key, required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.55)),
                  color: AppColors.gold.withValues(alpha: 0.12),
                ),
                child: Icon(Icons.check_rounded, size: 14, color: AppColors.goldLight),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(items[i], style: TarotTypography.body(size: 13.5))),
            ],
          ),
        ],
      ],
    );
  }

  static List<String> fromReading(String text) {
    final parts = text
        .split(RegExp(r'[\n\.]'))
        .map((s) => s.trim())
        .where((s) => s.length > 12)
        .take(3)
        .toList();
    return parts;
  }
}
