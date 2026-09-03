/// Soft quality / error whisper under the cup preview.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import 'coffee_reference_tokens.dart';

class CoffeeCaptureHint extends StatelessWidget {
  const CoffeeCaptureHint(
    this.text, {
    super.key,
    required this.attention,
    this.edgeInset = true,
  });

  final String text;
  final bool attention;
  final bool edgeInset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        edgeInset ? CoffeeReferenceTokens.screenHorizontal : 0,
        0,
        edgeInset ? CoffeeReferenceTokens.screenHorizontal : 0,
        CoffeeReferenceTokens.gap,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: CoffeeReferenceTokens.cardRadius,
          color: OraclyChrome.midnight.withValues(alpha: 0.72),
          border: Border.all(
            color: OraclyChrome.gold.withValues(
              alpha: attention ? 0.36 : 0.22,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                attention
                    ? Icons.wb_twilight_outlined
                    : Icons.info_outline_rounded,
                size: 18,
                color: OraclyChrome.goldLight.withValues(alpha: 0.82),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: ReadingTypography.footnote(
                    color: OraclyChrome.cream.withValues(alpha: 0.88),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
