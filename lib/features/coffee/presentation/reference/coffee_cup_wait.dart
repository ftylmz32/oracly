/// Ceremonial wait over the selected cup — real photo, quiet analysis veil.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import 'coffee_analysis_veil.dart';
import 'coffee_gold_preview.dart';
import 'coffee_reference_tokens.dart';

class CoffeeCupWait extends StatelessWidget {
  const CoffeeCupWait({
    super.key,
    required this.message,
    required this.path,
    this.subtitle,
    this.fixedHeight,
  });

  final String message;
  final String path;
  final String? subtitle;
  final double? fixedHeight;

  @override
  Widget build(BuildContext context) {
    final preview = CoffeeAnalysisVeil(
      child: CoffeeGoldPreview(
        path: path,
        contain: true,
        hero: true,
      ),
    );
    final cup = fixedHeight == null
        ? Expanded(child: preview)
        : SizedBox(height: fixedHeight, child: preview);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: CoffeeReferenceTokens.screenHorizontal * 0.45,
      ),
      child: Column(
        children: [
          cup,
          if (message.isNotEmpty) ...[
            SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: ReadingTypography.opening(
                  color: OraclyChrome.cream.withValues(alpha: 0.92),
                ),
              ),
            ),
          ],
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            SizedBox(height: AppSpacing.sm),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: ReadingTypography.secondary(
                color: OraclyChrome.cream.withValues(alpha: 0.72),
              ),
            ),
          ],
          if (message.isNotEmpty || (subtitle != null && subtitle!.isNotEmpty))
            SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
