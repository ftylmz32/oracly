/// Custom reference toggle — gold glow, no Material switch.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/oracly_pressable.dart';
import 'settings_reference_tokens.dart';

class SettingsReferenceSwitch extends StatelessWidget {
  const SettingsReferenceSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return OraclyPressable(
      onTap: () => onChanged(!value),
      // Intentional soft cue when Ses efektleri is ON (gate blocks when OFF).
      softSound: true,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: SettingsReferenceTokens.switchWidth,
        height: SettingsReferenceTokens.switchHeight,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(
            colors: value
                ? [
                    palette.gold.withValues(alpha: 0.72),
                    palette.gold.withValues(alpha: 0.82),
                  ]
                : [
                    palette.surface.withValues(alpha: 0.55),
                    palette.background.withValues(alpha: 0.62),
                  ],
          ),
          border: Border.all(
            color: palette.gold.withValues(alpha: value ? 0.55 : 0.22),
          ),
          boxShadow: value
              ? [
                  BoxShadow(
                    color: palette.gold.withValues(alpha: 0.32),
                    blurRadius: 12,
                    spreadRadius: -1,
                  ),
                ]
              : null,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value
                  ? palette.background.withValues(alpha: 0.92)
                  : palette.textSecondary.withValues(alpha: 0.72),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SizedBox(
              width: SettingsReferenceTokens.switchThumbSize,
              height: SettingsReferenceTokens.switchThumbSize,
            ),
          ),
        ),
      ),
    );
  }
}
