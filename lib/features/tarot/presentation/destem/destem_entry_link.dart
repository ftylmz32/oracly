/// Quiet Destem entry — off the draw CTA.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../epic031/tarot_epic031_spec.dart';
import 'destem_copy.dart';

class DestemEntryLink extends StatelessWidget {
  const DestemEntryLink({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: OraclyPressable(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            DestemCopy.link,
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
