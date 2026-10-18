/// Birth date wheel — three columns, no keyboard, nothing saved until Onayla.
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../../core/copy/onboarding_copy.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/oracly_pressable.dart';

/// Opens the wheel. Returns a local calendar date (midnight, no zone shift),
/// or null when the sheet is dismissed or Vazgeç is tapped.
Future<DateTime?> showEncounterBirthWheel(
  BuildContext context, {
  DateTime? initial,
  DateTime? today,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: const Color(0x00000000),
    barrierColor: AppColors.nearBlack.withValues(alpha: 0.62),
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => EncounterBirthWheel(initial: initial, today: today),
  );
}

/// Calendar-only copy of [value]; drops time so no zone can move the day.
DateTime encounterDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);

class EncounterBirthWheel extends StatefulWidget {
  const EncounterBirthWheel({super.key, this.initial, this.today});

  final DateTime? initial;
  final DateTime? today;

  @override
  State<EncounterBirthWheel> createState() => _EncounterBirthWheelState();
}

class _EncounterBirthWheelState extends State<EncounterBirthWheel> {
  static const _extent = 44.0;

  late final DateTime _max = encounterDay(widget.today ?? DateTime.now());
  late final DateTime _min = DateTime(_max.year - 100);
  late DateTime _value = _start();

  DateTime _start() {
    final seed = widget.initial == null
        ? DateTime(_max.year - 25)
        : encounterDay(widget.initial!);
    if (seed.isAfter(_max)) return _max;
    if (seed.isBefore(_min)) return _min;
    return seed;
  }

  @override
  Widget build(BuildContext context) {
    // Material chrome may run in English; the wheel speaks the app language.
    final code = OraclyL10n.code;
    final media = MediaQuery.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.crystalVeil, AppColors.chamberViolet],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.gold.withValues(alpha: 0.45)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            OnboardingCopy.birthLabel,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.goldLight,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: _extent * 5,
            child: Stack(
              alignment: Alignment.center,
              children: [
                IgnorePointer(
                  child: Container(
                    height: _extent,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                // The wheel keeps its own rhythm; very large text would clip rows.
                MediaQuery(
                  data: media.copyWith(
                    textScaler: media.textScaler.clamp(maxScaleFactor: 1.15),
                  ),
                  child: Localizations.override(
                    context: context,
                    locale: Locale(code),
                    delegates: const [GlobalCupertinoLocalizations.delegate],
                    child: CupertinoTheme(
                      data: CupertinoThemeData(
                        brightness: Brightness.dark,
                        textTheme: CupertinoTextThemeData(
                          dateTimePickerTextStyle: AppTextStyles.bodyLarge
                              .copyWith(
                                color: AppColors.goldLight,
                                fontSize: 21,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      child: CupertinoDatePicker(
                        key: const ValueKey('encounter-birth-wheel'),
                        mode: CupertinoDatePickerMode.date,
                        dateOrder: code == 'en'
                            ? null
                            : DatePickerDateOrder.dmy,
                        initialDateTime: _value,
                        minimumDate: _min,
                        maximumDate: _max,
                        itemExtent: _extent,
                        backgroundColor: const Color(0x00000000),
                        selectionOverlayBuilder:
                            (
                              context, {
                              required columnCount,
                              required selectedIndex,
                            }) => null,
                        onDateTimeChanged: (value) =>
                            setState(() => _value = encounterDay(value)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _WheelButton(
                  label: OnboardingCopy.birthCancel,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _WheelButton(
                  label: OnboardingCopy.birthConfirm,
                  strong: true,
                  onTap: () => Navigator.of(context).pop(_value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WheelButton extends StatelessWidget {
  const _WheelButton({
    required this.label,
    required this.onTap,
    this.strong = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return OraclyPressable(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: strong
              ? const LinearGradient(
                  colors: [AppColors.goldLight, AppColors.goldDeep],
                )
              : null,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: strong
                ? AppColors.goldLight
                : AppColors.gold.withValues(alpha: 0.45),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.labelLarge.copyWith(
            color: strong ? AppColors.chamberViolet : AppColors.goldLight,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
