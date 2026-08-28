/// OR-437 — Personal reflection block on history detail.
library;

import 'package:flutter/material.dart';

import '../../../../../core/copy/transparency_copy.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/reading_typography.dart';
import '../../../../../shared/widgets/oracly_text_action.dart';

class ReadingJournalReflectionCard extends StatelessWidget {
  const ReadingJournalReflectionCard({
    super.key,
    required this.note,
    required this.onEdit,
  });

  final String? note;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final hasNote = note != null && note!.trim().isNotEmpty;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.lg,
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceElevated.withValues(alpha: 0.88),
            AppColors.surface.withValues(alpha: 0.82),
          ],
        ),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: hasNote ? 0.32 : 0.20),
          width: AppBorderWidth.hairline,
        ),
      ),
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  size: 18,
                  color: AppColors.goldLight.withValues(alpha: 0.85),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Kişisel Yansıma',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.goldLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                OraclyTextAction(
                  label: hasNote ? 'Düzenle' : 'Ekle',
                  emphasized: true,
                  onPressed: onEdit,
                ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              hasNote
                  ? note!.trim()
                  : TransparencyCopy.journalEmptyPrompt,
              style: hasNote
                  ? ReadingTypography.bodySmall()
                  : ReadingTypography.footnote(),
            ),
          ],
        ),
      ),
    );
  }
}
