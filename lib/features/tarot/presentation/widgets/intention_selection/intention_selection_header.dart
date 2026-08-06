/// OR-404 — Ceremonial header for intention ritual.
library;

import 'package:flutter/material.dart';

import '../../../../../core/copy/first_session_copy.dart';
import '../../../../../core/first_session/first_session_scope.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../tarot_home/oracly_sacred_identity.dart';
import '../tarot_home/tarot_home_ornaments.dart';

class IntentionSelectionHeader extends StatelessWidget {
  const IntentionSelectionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isFirstSession = FirstSessionScope.of(context);
    final title = FirstSessionCopy.intentionTitleFor(
      isFirstSession: isFirstSession,
    );
    final subtitle = FirstSessionCopy.intentionSubtitleFor(
      isFirstSession: isFirstSession,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: OraclySacredPalette.champagne.withValues(alpha: 0.92),
            fontWeight: FontWeight.w600,
            letterSpacing: isFirstSession ? 2.0 : 3.0,
            fontSize: 13,
            height: 1.25,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        const TarotHomeGoldDivider(),
        SizedBox(height: AppSpacing.md + AppSpacing.xs),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.85),
              height: 1.65,
              fontSize: 13.5,
              letterSpacing: 0.25,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
