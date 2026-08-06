import 'package:flutter/material.dart';

import '../utils/tarot_reading_parser.dart';
import 'tarot_glass_panel.dart';
import 'tarot_oracle_header.dart';
import 'tarot_typography.dart';

class TarotInterpretationSections extends StatelessWidget {
  const TarotInterpretationSections({
    super.key,
    required this.sections,
  });

  final TarotReadingSections sections;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TarotOracleHeader(),
        const SizedBox(height: 16),
        TarotGlassPanel(
          title: 'Kart Mesajı',
          body: sections.cardMessage,
          icon: Icons.mail_outline_rounded,
          delayMs: 0,
        ),
        const SizedBox(height: 12),
        TarotGlassPanel(
          title: 'İç Anlam',
          body: sections.innerMeaning,
          icon: Icons.visibility_outlined,
          delayMs: 80,
        ),
        const SizedBox(height: 12),
        TarotGlassPanel(
          title: 'Rehberlik',
          body: sections.guidance,
          icon: Icons.navigation_outlined,
          delayMs: 160,
        ),
        const SizedBox(height: 12),
        TarotGlassPanel(
          title: 'Günün Yansıması',
          body: sections.dailyReflection,
          icon: Icons.nightlight_round_outlined,
          delayMs: 240,
        ),
      ],
    );
  }
}

/// Loading oracle state for interpretation area.
class TarotInterpretationLoading extends StatelessWidget {
  const TarotInterpretationLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 1.2,
                color: TarotTypography.sectionGold().color,
              ),
            ),
            const SizedBox(height: 16),
            Text('Oracle konuşuyor...', style: TarotTypography.captionMuted()),
          ],
        ),
      ),
    );
  }
}
