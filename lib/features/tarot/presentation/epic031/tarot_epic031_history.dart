/// EPIC-031 — Secondary “Geçmiş Fallarım >” link (reference).
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import 'tarot_epic031_spec.dart';

class TarotEpic031History extends StatelessWidget {
  const TarotEpic031History({
    super.key,
    this.onViewAll,
    this.onEntryTap,
  });

  final VoidCallback? onViewAll;
  final VoidCallback? onEntryTap;

  static const String title = 'Geçmiş Fallarım >';

  @override
  Widget build(BuildContext context) {
    final onTap = onViewAll ?? onEntryTap;

    return Center(
      child: OraclyPressable(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            title,
            style: AppTextStyles.labelMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.90),
              fontWeight: FontWeight.w500,
              letterSpacing: TarotEpic031Spec.historyLabelTracking,
              fontSize: TarotEpic031Spec.historyLabelSize,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}
