import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../components/tarot_loading.dart';
import '../utils/tarot_reading_parser.dart';
import 'tarot_glass_panel.dart';
import 'tarot_oracle_header.dart';

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
          title: OraclyL10n.t('tarot.panel.card_message'),
          body: sections.cardMessage,
          icon: Icons.mail_outline_rounded,
          delayMs: 0,
        ),
        const SizedBox(height: 12),
        TarotGlassPanel(
          title: OraclyL10n.t('tarot.panel.inner_meaning'),
          body: sections.innerMeaning,
          icon: Icons.visibility_outlined,
          delayMs: 80,
        ),
        const SizedBox(height: 12),
        TarotGlassPanel(
          title: OraclyL10n.t('tarot.panel.guidance'),
          body: sections.guidance,
          icon: Icons.navigation_outlined,
          delayMs: 160,
        ),
        const SizedBox(height: 12),
        TarotGlassPanel(
          title: OraclyL10n.t('tarot.panel.daily_reflection'),
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
      height: 220,
      child: TarotLoading(
        message: OraclyL10n.t('tarot.oracle_speaking'),
        compact: true,
      ),
    );
  }
}
