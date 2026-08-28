/// Category picker for support reports — predefined options only.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_radius.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_button.dart';
import '../../../reading_feedback/presentation/widgets/reading_feedback_category_row.dart';
import '../../copy/help_copy.dart';
import '../../models/support_category.dart';

Future<SupportCategory?> showHelpReportSheet(BuildContext context) {
  return showModalBottomSheet<SupportCategory>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: AppColors.transparent,
    builder: (_) => const _HelpReportSheet(),
  );
}

class _HelpReportSheet extends StatefulWidget {
  const _HelpReportSheet();

  @override
  State<_HelpReportSheet> createState() => _HelpReportSheetState();
}

class _HelpReportSheetState extends State<_HelpReportSheet> {
  SupportCategory? _category;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
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
              color: palette.surface.withValues(alpha: 0.95),
              border: Border(
                top: BorderSide(
                  color: palette.gold.withValues(alpha: 0.28),
                  width: AppBorderWidth.hairline,
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      HelpCopy.reportTitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: palette.goldLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      HelpCopy.reportHint,
                      textAlign: TextAlign.center,
                      style: ReadingTypography.footnote(),
                    ),
                    SizedBox(height: AppSpacing.md),
                    for (final value in SupportCategory.values)
                      ReadingFeedbackCategoryRow(
                        label: HelpCopy.category(value),
                        selected: _category == value,
                        onTap: () => setState(() => _category = value),
                      ),
                    SizedBox(height: AppSpacing.md),
                    OraclyButton(
                      text: HelpCopy.send,
                      isExpanded: true,
                      onPressed: _category == null
                          ? null
                          : () => Navigator.pop(context, _category),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
