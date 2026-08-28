/// Category sheet — optional free reinterpret, clearly labeled.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_radius.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_button.dart';
import '../../copy/reading_feedback_copy.dart';
import '../../models/reading_feedback_category.dart';
import 'reading_feedback_category_row.dart';

enum ReadingFeedbackChoice { send, retry }

class ReadingFeedbackSheetResult {
  const ReadingFeedbackSheetResult({
    required this.category,
    required this.choice,
  });

  final ReadingFeedbackCategory category;
  final ReadingFeedbackChoice choice;
}

Future<ReadingFeedbackSheetResult?> showReadingFeedbackSheet({
  required BuildContext context,
  required bool canRetry,
}) {
  return showModalBottomSheet<ReadingFeedbackSheetResult>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: AppColors.transparent,
    builder: (_) => _Sheet(canRetry: canRetry),
  );
}

class _Sheet extends StatefulWidget {
  const _Sheet({required this.canRetry});

  final bool canRetry;

  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  ReadingFeedbackCategory? _category;

  void _pop(ReadingFeedbackChoice choice) {
    final category = _category;
    if (category == null) return;
    Navigator.pop(
      context,
      ReadingFeedbackSheetResult(category: category, choice: choice),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              color: AppColors.of(context).surface.withValues(alpha: 0.95),
              border: Border(
                top: BorderSide(
                  color: AppColors.of(context).gold.withValues(alpha: 0.28),
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
                      ReadingFeedbackCopy.title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.of(context).goldLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      ReadingFeedbackCopy.hint,
                      textAlign: TextAlign.center,
                      style: ReadingTypography.footnote(),
                    ),
                    SizedBox(height: AppSpacing.md),
                    for (final value in QualityIssue.values)
                      ReadingFeedbackCategoryRow(
                        label: ReadingFeedbackCopy.category(value),
                        selected: _category == value,
                        onTap: () => setState(() => _category = value),
                      ),
                    if (widget.canRetry) ...[
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        ReadingFeedbackCopy.retryNote,
                        textAlign: TextAlign.center,
                        style: ReadingTypography.footnote(),
                      ),
                    ],
                    SizedBox(height: AppSpacing.md),
                    OraclyButton(
                      text: ReadingFeedbackCopy.send,
                      isExpanded: true,
                      onPressed: _category == null
                          ? null
                          : () => _pop(ReadingFeedbackChoice.send),
                    ),
                    if (widget.canRetry) ...[
                      SizedBox(height: AppSpacing.sm),
                      OraclyButton(
                        text: ReadingFeedbackCopy.retry,
                        type: OraclyButtonType.ghost,
                        isExpanded: true,
                        onPressed: _category == null
                            ? null
                            : () => _pop(ReadingFeedbackChoice.retry),
                      ),
                    ],
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
