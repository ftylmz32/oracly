/// Settings choice sheet — Material-safe options (no broken ListTile ink).
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/audio/oracly_feedback_gate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/oracly_pressable.dart';

Future<T?> showSettingsChoiceSheet<T>({
  required BuildContext context,
  required String title,
  required List<(T value, String label)> options,
  required T current,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    backgroundColor: AppColors.transparent,
    builder: (sheetContext) {
      return Material(
        color: AppColors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xlValue),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.of(
                  sheetContext,
                ).surface.withValues(alpha: 0.95),
                border: Border(
                  top: BorderSide(
                    color: AppColors.of(
                      sheetContext,
                    ).gold.withValues(alpha: 0.28),
                    width: AppBorderWidth.hairline,
                  ),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        title,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: AppColors.of(sheetContext).goldLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    for (final opt in options)
                      _ChoiceRow(
                        label: opt.$2,
                        selected: opt.$1 == current,
                        onTap: () => Navigator.pop(sheetContext, opt.$1),
                      ),
                    SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return OraclyPressable(
      onTap: () {
        OraclyTouchFeedback.selection();
        OraclyFeedbackGate.selection();
        onTap();
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: selected ? palette.goldLight : palette.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
            if (selected) Icon(Icons.check_rounded, color: palette.gold),
          ],
        ),
      ),
    );
  }
}
