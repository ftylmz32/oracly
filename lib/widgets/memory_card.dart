import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_duration.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../models/memory_item.dart';
import 'glass_card.dart';

class MemoryCard extends StatelessWidget {
  final List<MemoryItem> memories;

  const MemoryCard({
    super.key,
    required this.memories,
  });

  @override
  Widget build(BuildContext context) {
    final hasMemory = memories.isNotEmpty;
    final countLabel = '${memories.length} hafıza';

    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .08),
                  borderRadius: AppRadius.md,
                ),
                child: Icon(
                  Icons.psychology_rounded,
                  size: 20,
                  color: AppColors.gold.withValues(alpha: .8),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Hafıza',
                  style: AppTextStyles.title.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .05),
                  borderRadius: AppRadius.round,
                  border: Border.all(
                    color: AppColors.glassBorder,
                  ),
                ),
                child: Text(
                  countLabel,
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textHint,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AnimatedSwitcher(
            duration: AppDuration.normal,
            child: hasMemory
                ? Text(
                    memories.first.content,
                    key: const ValueKey('memory'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.textPrimary.withValues(
                        alpha: .9,
                      ),
                      height: 1.5,
                    ),
                  )
                : Text(
                    'Seni tanımaya yeni başlıyorum.',
                    key: const ValueKey('empty'),
                    style: AppTextStyles.caption.copyWith(
                      height: 1.45,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
