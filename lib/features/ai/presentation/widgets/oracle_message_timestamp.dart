/// OR-1190 — Message timestamp label.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class OracleMessageTimestamp extends StatelessWidget {
  const OracleMessageTimestamp({
    super.key,
    required this.time,
    this.alignEnd = false,
  });

  final DateTime time;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return Padding(
      padding: EdgeInsets.only(
        top: AppSpacing.xs,
        left: alignEnd ? 0 : AppSpacing.xl + AppSpacing.sm,
        right: alignEnd ? AppSpacing.xl + AppSpacing.sm : 0,
      ),
      child: Text(
        '$h:$m',
        style: AppTextStyles.labelMedium.copyWith(
          fontSize: 10,
          color: AppColors.textMuted.withValues(alpha: 0.75),
        ),
      ),
    );
  }
}
