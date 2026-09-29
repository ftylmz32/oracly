/// Quiet chamber while a saved portrait is still being read.
///
/// Not a paywall, not a form, and not a claim that a portrait exists.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_layout.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/soul_mate_copy.dart';
import '../reference/premium_reference_tokens.dart';

class SoulMateDrawOpening extends StatelessWidget {
  const SoulMateDrawOpening({super.key});

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
      ],
    );
  }
}
