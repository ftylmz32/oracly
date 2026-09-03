/// EPIC-011 — Private thought capture for the daily ritual.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/app_layout.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../shared/widgets/oracly_gold_button.dart';
import '../../../shared/widgets/oracly_text_action.dart';

/// Opens a calm bottom sheet for one personal thought — no pressure.
Future<String?> showDailyRitualThoughtSheet({
  required BuildContext context,
  String? initialThought,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _DailyRitualThoughtSheet(
      initialThought: initialThought,
    ),
  );
}

class _DailyRitualThoughtSheet extends StatefulWidget {
  const _DailyRitualThoughtSheet({this.initialThought});

  final String? initialThought;

  @override
  State<_DailyRitualThoughtSheet> createState() =>
      _DailyRitualThoughtSheetState();
}

class _DailyRitualThoughtSheetState extends State<_DailyRitualThoughtSheet> {
  late final TextEditingController _note;
  static const _maxLength = 280;

  @override
  void initState() {
    super.initState();
    _note = TextEditingController(text: widget.initialThought ?? '');
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: AppLayout.sheetBottomInset(context),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.surfaceElevated.withValues(alpha: 0.98),
              AppColors.surface.withValues(alpha: 0.96),
            ],
          ),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.28),
            width: AppBorderWidth.hairline,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.35),
                    borderRadius: AppRadius.round,
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              Text(
                OraclyL10n.t('ritual.thought.title'),
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.goldLight.withValues(alpha: 0.92),
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                OraclyL10n.t('ritual.thought.sub'),
                style: ReadingTypography.bodySmall(),
              ),
              SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _note,
                maxLength: _maxLength,
                maxLines: 4,
                style: ReadingTypography.body(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: OraclyL10n.t('ritual.thought.hint'),
                  hintStyle: ReadingTypography.body(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.background.withValues(alpha: 0.45),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.md,
                    borderSide: BorderSide(
                      color: AppColors.gold.withValues(alpha: 0.18),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.md,
                    borderSide: BorderSide(
                      color: AppColors.gold.withValues(alpha: 0.18),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.md,
                    borderSide: BorderSide(
                      color: AppColors.gold.withValues(alpha: 0.42),
                    ),
                  ),
                  counterStyle: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  OraclyTextAction(
                    label: OraclyL10n.t('ritual.thought.later'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OraclyGoldButton(
                      label: OraclyL10n.t(L10nKeys.save),
                      expanded: true,
                      onPressed: () =>
                          Navigator.of(context).pop(_note.text.trim()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
