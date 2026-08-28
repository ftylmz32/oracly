/// OR-1070 — History journal header copy.
library;

import 'package:flutter/material.dart';

import '../../../../../core/copy/transparency_copy.dart';
import '../../../../../core/design_system/app_icons.dart';
import '../../../../../core/design_system/oracly_header_action.dart';
import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/reading_typography.dart';

class ReadingHistoryHeader extends StatelessWidget {
  const ReadingHistoryHeader({super.key});

  static String get title => OraclyL10n.t('history.journey');
  static String get subtitle => TransparencyCopy.journeyOwnership;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        canPop ? AppSpacing.sm : AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canPop) ...[
            OraclyHeaderAction(
              icon: AppIcons.back,
              label: OraclyL10n.t(L10nKeys.back),
              onTap: () => Navigator.of(context).pop(),
            ),
            SizedBox(width: AppSpacing.xs),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.goldLight,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: ReadingTypography.body(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
