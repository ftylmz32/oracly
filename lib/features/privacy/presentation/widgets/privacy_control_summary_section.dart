/// Stored-data summary for the privacy control center.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../copy/privacy_control_copy.dart';
import '../../models/privacy_control_snapshot.dart';
import 'privacy_control_summary_row.dart';

class PrivacyControlSummarySection extends StatelessWidget {
  const PrivacyControlSummarySection({super.key, required this.snapshot});

  final PrivacyControlSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrivacyControlSummaryRow(
          label: PrivacyControlCopy.profile,
          value: snapshot.profileLabel,
        ),
        PrivacyControlSummaryRow(
          label: PrivacyControlCopy.moments,
          value: snapshot.favoriteCount == 0
              ? PrivacyControlCopy.empty
              : PrivacyControlCopy.count(snapshot.favoriteCount),
        ),
        PrivacyControlSummaryRow(
          label: PrivacyControlCopy.history,
          value: snapshot.discoveryCount == 0
              ? PrivacyControlCopy.empty
              : PrivacyControlCopy.count(snapshot.discoveryCount),
        ),
        PrivacyControlSummaryRow(
          label: PrivacyControlCopy.memory,
          value: snapshot.memorySummary,
        ),
        PrivacyControlSummaryRow(
          label: PrivacyControlCopy.notifications,
          value: snapshot.notificationsLabel,
        ),
        PrivacyControlSummaryRow(
          label: PrivacyControlCopy.voice,
          value: snapshot.voiceLabel,
        ),
        SizedBox(height: AppSpacing.md),
      ],
    );
  }
}
