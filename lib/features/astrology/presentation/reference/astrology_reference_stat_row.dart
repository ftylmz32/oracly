/// Honest theme note - no invented Ask / Kariyer / Enerji scores.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/craftsmanship_rhythm.dart';
import '../../../../core/theme/reading_typography.dart';
import 'astrology_reference_card_shell.dart';
import 'astrology_reference_tokens.dart';

class AstrologyReferenceStatRow extends StatelessWidget {
  const AstrologyReferenceStatRow({super.key});

  static const honestyNote =
      'G\u00fcne\u015f burcuna g\u00f6re sembolik bir yans\u0131ma. Say\u0131sal skor yok.';

  @override
  Widget build(BuildContext context) {
    return AstrologyReferenceCardShell(
      borderRadius: AstrologyReferenceTokens.statBoxRadius,
      padding: OraclyChrome.cardPadding,
      premium: true,
      glowStrength: 1.08,
      child: Text(
        honestyNote,
        textAlign: TextAlign.center,
        style: ReadingTypography.footnote(
          color: OraclyChrome.cream.withValues(
            alpha: CraftsmanshipRhythm.secondaryInk,
          ),
        ),
      ),
    );
  }
}
