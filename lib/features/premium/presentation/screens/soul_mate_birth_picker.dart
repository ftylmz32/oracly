/// Birth date picker themed for Premium atmosphere.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/oracly_gold_button.dart';
import '../../../../shared/widgets/oracly_text_action.dart';

Future<DateTime?> pickSoulMateBirthDate(
  BuildContext context, {
  DateTime? current,
}) {
  final now = DateTime.now();
  var selected = current ?? DateTime(now.year - 25);

  return showDialog<DateTime>(
    context: context,
    builder: (dialogContext) {
      final media = MediaQuery.of(dialogContext);
      final maxWidth = (media.size.width - 24).clamp(280.0, 400.0);
      final maxHeight = (media.size.height * 0.56).clamp(320.0, 440.0);
      return Theme(
        data: Theme.of(dialogContext).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.gold,
            onPrimary: AppColors.background,
            surface: AppColors.surfaceElevated,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          contentPadding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
          content: SizedBox(
            width: maxWidth,
            height: maxHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const calendarMinWidth = 360.0;
                final calendarWidth = math.max(
                  constraints.maxWidth,
                  calendarMinWidth,
                );
                final picker = SizedBox(
                  width: calendarWidth,
                  height: constraints.maxHeight,
                  child: CalendarDatePicker(
                    initialDate: selected,
                    firstDate: DateTime(1920),
                    lastDate: now,
                    currentDate: now,
                    onDateChanged: (next) => selected = next,
                  ),
                );
                if (calendarWidth <= constraints.maxWidth) return picker;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: picker,
                );
              },
            ),
          ),
          actions: [
            OraclyTextAction(
              label: MaterialLocalizations.of(dialogContext).cancelButtonLabel,
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            OraclyGoldButton(
              label: MaterialLocalizations.of(dialogContext).okButtonLabel,
              onPressed: () => Navigator.of(dialogContext).pop(selected),
            ),
          ],
        ),
      );
    },
  );
}
