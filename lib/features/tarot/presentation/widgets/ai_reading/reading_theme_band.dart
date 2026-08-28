/// Main theme motifs — short keyword line under the cards.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/reading_typography.dart';
import '../../../copy/tarot_polish_copy.dart';
import '../../../deck/oracly_tarot_bridge.dart';
import '../../../domain/models/reading_session.dart';
import 'ai_reading_content.dart';

class ReadingThemeBand extends StatelessWidget {
  const ReadingThemeBand({super.key, required this.content});

  final AiReadingContent content;

  static List<String> motifsOf(AiReadingContent content) {
    final seen = <String>{};
    final out = <String>[];
    for (final card in content.drawnCards) {
      for (final key in _keys(card)) {
        final t = key.trim();
        if (t.isEmpty || !seen.add(t.toLowerCase())) continue;
        out.add(t);
        if (out.length >= 3) return out;
      }
    }
    return out;
  }

  static List<String> _keys(TarotDrawnCard card) {
    final bridge = OraclyTarotBridge.keywords(card.card.id);
    if (bridge.isNotEmpty) return bridge;
    return card.card.keywords;
  }

  @override
  Widget build(BuildContext context) {
    final motifs = motifsOf(content);
    if (motifs.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        children: [
          Text(
            TarotPolishCopy.themeTitle,
            textAlign: TextAlign.center,
            style: ReadingTypography.sectionLabel(
              color: AppColors.gold.withValues(alpha: 0.72),
              fontSize: 10,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            motifs.join(' · '),
            textAlign: TextAlign.center,
            style: ReadingTypography.body(
              color: AppColors.cream.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}
