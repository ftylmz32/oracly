/// Subtle draw tutorial — fades permanently after first interaction.
library;

import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class TarotTableHint extends StatelessWidget {
  const TarotTableHint({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 420),
      opacity: visible ? 1 : 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.keyboard_double_arrow_up_rounded,
            color: AppColors.gold.withValues(alpha: 0.55),
            size: 18,
          ),
          const SizedBox(height: 4),
          Text(
            OraclyL10n.t('tarot.ritual.draw_hint'),
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.85),
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
