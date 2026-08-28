/// Discovery Journal — few recent entries, open full archive separately.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/navigation/oracly_navigation_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../features/discovery_journal/copy/discovery_journal_copy.dart';
import '../../../features/discovery_journal/providers/discovery_journal_providers.dart';
import '../copy/profile_copy.dart';
import 'profile_chamber_chrome.dart';
import 'profile_reference_card_shell.dart';
import 'profile_surface_weight.dart';

class ProfileJournalCompact extends ConsumerWidget {
  const ProfileJournalCompact({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items =
        ref.watch(discoveryJournalEntriesProvider).valueOrNull ?? const [];
    final recent = items.take(3).toList();

    return ProfileReferenceCardShell(
      weight: ProfileSurfaceWeight.story,
      glowStrength: 0.66,
      onTap: () => OraclyNavigationService.openDiscoveryJournal(context),
      child: ProfileChamberRail(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileChamberTitle(title: ProfileCopy.journalTitle),
            SizedBox(height: ProfileChamberGap.afterTitle),
            if (recent.isEmpty)
              Text(
                DiscoveryJournalCopy.emptyTitle,
                softWrap: true,
                style: ReadingTypography.body(
                  color: OraclyChrome.cream.withValues(alpha: 0.74),
                ),
              )
            else
              for (var i = 0; i < recent.length; i++) ...[
                if (i > 0) ...[
                  SizedBox(height: AppSpacing.s8),
                  ColoredBox(
                    color: OraclyChrome.gold.withValues(alpha: 0.12),
                    child: const SizedBox(height: 1, width: double.infinity),
                  ),
                  SizedBox(height: AppSpacing.s8),
                ],
                Text(
                  '${DiscoveryJournalCopy.badge(recent[i].kind)} · '
                  '${recent[i].title}',
                  softWrap: true,
                  style: ReadingTypography.body(
                    color: OraclyChrome.cream.withValues(alpha: 0.84),
                  ),
                ),
              ],
            SizedBox(height: ProfileChamberGap.beforeCta),
            ProfileChamberCta(label: ProfileCopy.journalBridgeOpenCta),
          ],
        ),
      ),
    );
  }
}
