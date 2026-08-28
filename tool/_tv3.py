from pathlib import Path

w = Path("lib/features/tarot/presentation/epic031/tarot_epic031_title_block.dart").write_text
body = """/// Invitation under TAROT — chamber mood, no certainty.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/tarot_polish_copy.dart';

class TarotEpic031TitleBlock extends StatelessWidget {
  const TarotEpic031TitleBlock({super.key});

  static String instruction = TarotPolishCopy.startInstruction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, AppSpacing.sm, 16, 0),
      child: Column(
        children: [
          Text(
            instruction,
            textAlign: TextAlign.center,
            style: ReadingTypography.opening(
              color: AppColors.cream.withValues(alpha: 0.94),
            ).copyWith(fontSize: 18, height: 1.35, letterSpacing: 0.2),
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.gold.withValues(alpha: 0.36),
                  Colors.transparent,
                ],
              ),
            ),
            child: const SizedBox(width: 56, height: 1),
          ),
        ],
      ),
    );
  }
}
"""
Path("lib/features/tarot/presentation/epic031/tarot_epic031_title_block.dart").write_text(body, encoding="utf-8", newline="\n")
print("title", len(body.splitlines()))

# Wire reveal complete whisper - find card reveal screen footer
