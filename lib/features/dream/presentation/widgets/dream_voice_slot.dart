/// SPRINT-001 — Voice input placeholder (future-ready).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/dream_copy.dart';
import '../../providers/dream_providers.dart';

class DreamVoiceSlot extends ConsumerWidget {
  const DreamVoiceSlot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voice = ref.watch(dreamVoiceInputProvider);

    return Opacity(
      opacity: voice.isAvailable ? 1 : 0.55,
      child: Row(
        children: [
          Icon(
            Icons.mic_none_rounded,
            color: AppColors.gold.withValues(alpha: 0.7),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DreamCopy.voiceLabel, style: ReadingTypography.bodySmall()),
                Text(
                  voice.isAvailable
                      ? 'Kayda başlamak için dokun'
                      : DreamCopy.voiceComingSoon,
                  style: ReadingTypography.footnote(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
