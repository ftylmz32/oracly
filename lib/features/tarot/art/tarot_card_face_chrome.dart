/// Face chrome — gold frame + obsidian title plaque (no text-on-art overlap).
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class TarotCardGoldFrame extends StatelessWidget {
  const TarotCardGoldFrame({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.72),
              width: 1.1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.goldLight.withValues(alpha: 0.38),
                  width: 0.65,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TarotCardTitlePlaque extends StatelessWidget {
  const TarotCardTitlePlaque({
    super.key,
    required this.text,
    this.letterSpacing = 1.4,
    this.size = 10,
  });

  final String text;
  final double letterSpacing;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF080512).withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.28),
          width: 0.6,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.goldLight.withValues(alpha: 0.94),
            fontWeight: FontWeight.w700,
            letterSpacing: letterSpacing,
            fontSize: size,
            height: 1.15,
          ),
        ),
      ),
    );
  }
}
