/// Destem meaning blocks for full card detail.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../deck/oracly_tarot_card.dart';

class DestemDetailSections extends StatelessWidget {
  const DestemDetailSections({super.key, required this.card});

  final OraclyTarotCard card;

  @override
  Widget build(BuildContext context) {
    final code = OraclyL10n.code;
    final blocks = <(String, String)>[
      (_t('tarot.destem.meaning.symbolic'), card.symbolicMeaning.of(code)),
      (_t('tarot.destem.meaning.love'), card.loveMeaning.of(code)),
      (_t('tarot.destem.meaning.career'), card.careerMeaning.of(code)),
      (_t('tarot.destem.meaning.money'), card.moneyMeaning.of(code)),
      (_t('tarot.destem.meaning.personal'), card.personalMeaning.of(code)),
      (_t('tarot.destem.meaning.challenge'), card.challengeMeaning.of(code)),
      (_t('tarot.destem.meaning.guidance'), card.guidanceMeaning.of(code)),
      (_t('tarot.destem.meaning.future'), card.futureDirectionMeaning.of(code)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final block in blocks)
          if (block.$2.trim().isNotEmpty) _Block(title: block.$1, body: block.$2),
      ],
    );
  }

  static String _t(String key) => OraclyL10n.t(key);
}

class _Block extends StatelessWidget {
  const _Block({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: ReadingTypography.sectionLabel(
              color: OraclyChrome.goldLight.withValues(alpha: 0.86),
              fontSize: 11,
            ),
          ),
          SizedBox(height: AppSpacing.s8),
          Text(
            body,
            style: ReadingTypography.body(
              color: OraclyChrome.cream.withValues(alpha: 0.86),
            ),
          ),
        ],
      ),
    );
  }
}
