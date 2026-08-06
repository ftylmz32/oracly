import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../models/memory_item.dart';
import 'glass_card.dart';
import 'oracly_icon.dart';

class MemoryCard extends StatelessWidget {
  const MemoryCard({super.key, required this.memories});

  final List<MemoryItem> memories;

  @override
  Widget build(BuildContext context) {
    final hasMemory = memories.isNotEmpty;
    final countLabel = '${memories.length} hafıza';

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                ),
                child: const OraclyIcon(Icons.psychology_rounded, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text('Hafıza', style: AppTextStyles.title),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Text(countLabel, style: AppTextStyles.small),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: AppDuration.normal,
            child: hasMemory
                ? Text(
                    memories.first.content,
                    key: const ValueKey('memory'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.textPrimary.withValues(alpha: 0.88),
                    ),
                  )
                : Text(
                    'Seni tanımaya yeni başlıyorum.',
                    key: const ValueKey('empty'),
                    style: AppTextStyles.caption.copyWith(height: 1.55),
                  ),
          ),
        ],
      ),
    );
  }
}
