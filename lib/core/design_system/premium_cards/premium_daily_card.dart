/// EPIC-023 — Daily ritual card: illustration left · content right.
library;

import 'package:flutter/material.dart';

import '../app_spacing.dart';
import '../premium_button.dart';
import 'premium_card_shell.dart';
import 'premium_card_tokens.dart';

/// Horizontal daily card — artwork ~40%, information + CTA on the right.
class PremiumDailyCard extends StatelessWidget {
  const PremiumDailyCard({
    super.key,
    required this.illustration,
    required this.content,
    this.primaryAction,
    this.secondaryActions,
    this.onTap,
    this.minHeight = 168,
  });

  final Widget illustration;
  final Widget content;
  final PremiumButton? primaryAction;
  final Widget? secondaryActions;
  final VoidCallback? onTap;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return PremiumCardShell(
      onTap: onTap,
      tier: PremiumCardTier.featured,
      glow: PremiumCardGlow.large,
      showShimmer: true,
      padding: EdgeInsets.all(AppSpacing.s20),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: PremiumCardTokens.illustrationFlex,
              child: illustration,
            ),
            SizedBox(width: AppSpacing.s16),
            Expanded(
              flex: PremiumCardTokens.contentFlex,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  content,
                  if (primaryAction != null) ...[
                    SizedBox(height: AppSpacing.s16),
                    primaryAction!,
                  ],
                  if (secondaryActions != null) ...[
                    SizedBox(height: AppSpacing.s12),
                    secondaryActions!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
