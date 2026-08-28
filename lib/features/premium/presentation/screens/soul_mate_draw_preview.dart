/// Locked Ruh Eşi chamber — atmosphere and unlocks, never a fake portrait.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_layout.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/soul_mate_copy.dart';
import '../reference/premium_entry_sheet.dart';
import '../reference/premium_reference_tokens.dart';

class SoulMateDrawPreview extends StatelessWidget {
  const SoulMateDrawPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        PremiumReferenceTokens.screenHorizontal,
        PremiumReferenceTokens.headerToHero,
        PremiumReferenceTokens.screenHorizontal,
        AppLayout.scrollBottomInset(context),
      ),
      children: [
        Text(
          SoulMateCopy.screenLead,
          textAlign: TextAlign.center,
          style: ReadingTypography.body(
            color: OraclyChrome.cream.withValues(alpha: 0.88),
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        const PremiumEntryBody(),
      ],
    );
  }
}
