/// Material date/time pickers themed for birth onboarding.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

typedef BirthPickerTheme = Widget Function(BuildContext, Widget?);

BirthPickerTheme birthPickerTheme() {
  return (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.gold,
            surface: AppColors.surfaceElevated,
          ),
        ),
        child: child!,
      );
}

Future<DateTime?> pickBirthDate(
  BuildContext context, {
  DateTime? current,
}) {
  final now = DateTime.now();
  return showDatePicker(
    context: context,
    initialDate: current ?? DateTime(now.year - 25),
    firstDate: DateTime(1920),
    lastDate: now,
    builder: birthPickerTheme(),
  );
}

Future<TimeOfDay?> pickBirthTime(
  BuildContext context, {
  TimeOfDay? current,
}) {
  return showTimePicker(
    context: context,
    initialTime: current ?? const TimeOfDay(hour: 12, minute: 0),
    builder: birthPickerTheme(),
  );
}