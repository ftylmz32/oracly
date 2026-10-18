/// Still gold action. The shared CTA's light sweep reads as a stripe here.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/oracly_pressable.dart';

class EncounterAction extends StatelessWidget {
  const EncounterAction({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return OraclyPressable(
      onTap: onPressed,
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: AppGradients.gold,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: AppColors.goldLight.withValues(alpha: 0.35),
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.background),
          ),
        ),
      ),
    );
  }
}
