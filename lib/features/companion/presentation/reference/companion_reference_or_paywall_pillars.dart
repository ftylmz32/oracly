/// OR paywall pillars — conversation qualities, never life-outcome promises.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/companion_copy.dart';

class CompanionReferenceOrPaywallPillars extends StatelessWidget {
  const CompanionReferenceOrPaywallPillars({super.key});

  static List<(String, String)> get _pillars => [
        (
          CompanionCopy.orPaywallPillarDepthTitle,
          CompanionCopy.orPaywallPillarDepthBody,
        ),
        (
          CompanionCopy.orPaywallPillarContinuityTitle,
          CompanionCopy.orPaywallPillarContinuityBody,
        ),
        (
          CompanionCopy.orPaywallPillarVoiceTitle,
          CompanionCopy.orPaywallPillarVoiceBody,
        ),
        (
          CompanionCopy.orPaywallPillarContextTitle,
          CompanionCopy.orPaywallPillarContextBody,
        ),
        (
          CompanionCopy.orPaywallPillarSessionsTitle,
          CompanionCopy.orPaywallPillarSessionsBody,
        ),
        (
          CompanionCopy.orPaywallPillarDiscoveryTitle,
          CompanionCopy.orPaywallPillarDiscoveryBody,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final pillar in _pillars) ...[
          _Pillar(title: pillar.$1, body: pillar.$2),
          SizedBox(height: AppSpacing.s12),
        ],
      ],
    );
  }
}

class _Pillar extends StatelessWidget {
  const _Pillar({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: ReadingTypography.sectionLabel(
            fontSize: 11,
            color: OraclyChrome.goldLight.withValues(alpha: 0.90),
          ),
        ),
        SizedBox(height: AppSpacing.s4),
        Text(
          body,
          style: ReadingTypography.bodySmall(
            color: OraclyChrome.cream.withValues(alpha: 0.78),
          ),
        ),
      ],
    );
  }
}
