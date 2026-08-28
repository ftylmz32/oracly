/// SPRINT-003 — Companion tab header.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_layout.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_text_action.dart';
import '../../copy/companion_copy.dart';

class CompanionHeader extends StatelessWidget {
  const CompanionHeader({
    super.key,
    required this.subtitle,
    required this.onMemoryTap,
  });

  final String subtitle;
  final VoidCallback onMemoryTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppLayout.screenPaddingHorizontal.copyWith(
        top: AppLayout.screenTop,
        bottom: AppLayout.labelToContent,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CompanionCopy.screenTitle,
                  style: ReadingTypography.cardTitle(),
                ),
                SizedBox(height: AppLayout.titleToSubtitle),
                Text(subtitle, style: ReadingTypography.opening()),
              ],
            ),
          ),
          OraclyTextAction(
            label: CompanionCopy.viewMemories,
            emphasized: true,
            onPressed: onMemoryTap,
          ),
        ],
      ),
    );
  }
}
