/// ORACLY'DEN BİR GÖZLEM — one observational line in the journal story.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../personal_discovery/models/oracly_observation.dart';
import '../../copy/discovery_journal_copy.dart';

class DiscoveryJournalObservation extends StatelessWidget {
  const DiscoveryJournalObservation({super.key, required this.observation});

  final OraclyObservation observation;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DiscoveryJournalCopy.observationTitle,
            style: ReadingTypography.sectionLabel(
              color: OraclyChrome.goldLight,
              fontSize: 11,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s8),
            child: Text(
              observation.line,
              style: ReadingTypography.body(
                color: OraclyChrome.cream.withValues(alpha: 0.88),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
