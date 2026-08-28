/// Soft quality / error whisper under the palm preview.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/reading_typography.dart';
import 'palm_tokens.dart';

class PalmCaptureHint extends StatelessWidget {
  const PalmCaptureHint(this.text, {super.key, this.attention = false});

  final String text;
  final bool attention;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: PalmTokens.cardRadius,
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
    );
  }
}
