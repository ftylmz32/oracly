/// Compact personal summary — real recurring theme chips only.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../features/personal_discovery/providers/personal_discovery_providers.dart';
import '../copy/profile_copy.dart';
import 'profile_discovery_summary.dart';
import 'profile_discovery_theme_chip.dart';
import 'profile_reference_card_shell.dart';

class ProfileDiscoveryInsightCard extends ConsumerWidget {
  const ProfileDiscoveryInsightCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discovery = ref.watch(personalDiscoveryProfileProvider).valueOrNull;
    final chips = discovery == null
        ? const []
        : ProfileDiscoverySummary.highlights(discovery);
    return ProfileReferenceCardShell(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ProfileCopy.discoveryInsightTitle,
              style: ReadingTypography.sectionLabel(
                color: OraclyChrome.goldLight,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            if (chips.isEmpty)
              Text(
                ProfileCopy.storyEmpty,
                style: ReadingTypography.body(
                  color: OraclyChrome.cream.withValues(alpha: 0.72),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final insight in chips)
                    ProfileDiscoveryThemeChip(insight: insight),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
