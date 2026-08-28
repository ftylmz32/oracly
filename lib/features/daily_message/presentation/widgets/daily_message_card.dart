/// Compact ritual glass — date, gold title, one reflection.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/design_system/oracly_glass_card.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/daily_message_copy.dart';
import '../../models/daily_message.dart';
import 'daily_message_moon.dart';

class DailyMessageCard extends StatelessWidget {
  const DailyMessageCard({super.key, required this.message});

  final DailyMessage message;

  @override
  Widget build(BuildContext context) {
    return OraclyGlassCard(
      elevated: true,
      glowStrength: 0.7,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: DailyMessageMoon()),
          const SizedBox(height: 8),
          Text(
            message.dateStamp.toUpperCase(),
            textAlign: TextAlign.center,
            style: ReadingTypography.sectionLabel(
              color: OraclyChrome.goldMuted.withValues(alpha: 0.78),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            DailyMessageCopy.prompt,
            textAlign: TextAlign.center,
            style: OraclyChrome.engravedTitle(size: 13),
          ),
          const SizedBox(height: 12),
          Text(
            message.text,
            textAlign: TextAlign.center,
            style: ReadingTypography.reflection(
              color: OraclyChrome.cream.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            DailyMessageCopy.honesty,
            textAlign: TextAlign.center,
            style: ReadingTypography.footnote(
              color: OraclyChrome.goldMuted.withValues(alpha: 0.62),
            ),
          ),
        ],
      ),
    );
  }
}
