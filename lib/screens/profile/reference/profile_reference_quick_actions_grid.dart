/// Quiet chamber destinations — sanctuary rows first, settings last.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/navigation/oracly_navigation_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/reading_typography.dart';
import '../copy/profile_copy.dart';
import 'profile_quick_action_row.dart';
import 'profile_reference_card_shell.dart';
import 'profile_surface_weight.dart';

class ProfileReferenceQuickActionsGrid extends StatelessWidget {
  const ProfileReferenceQuickActionsGrid({
    super.key,
    required this.onOpenSettings,
    this.includeJournal = true,
    this.includeSettings = true,
  });

  final VoidCallback onOpenSettings;
  final bool includeJournal;
  final bool includeSettings;

  @override
  Widget build(BuildContext context) {
    final room = <(IconData, String, VoidCallback)>[
      if (includeJournal)
        (
          Icons.auto_stories_outlined,
          ProfileCopy.journalTitle,
          () => OraclyNavigationService.openDiscoveryJournal(context),
        ),
      (
        Icons.forum_outlined,
        ProfileCopy.orTitle,
        () => OraclyNavigationService.openChat(context),
      ),
      (
        Icons.wb_twilight_outlined,
        ProfileCopy.dailyMessageTitle,
        () => OraclyNavigationService.openDailyMessage(context),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (room.isNotEmpty) ...[
          Text(
            ProfileCopy.roomSection,
            style: ReadingTypography.sectionLabel(fontSize: 11).copyWith(
              letterSpacing: 2.2,
              color: OraclyChrome.goldLight.withValues(alpha: 0.78),
            ),
          ),
          SizedBox(height: AppSpacing.s8),
          _ActionCard(rows: room),
        ],
        if (includeSettings) ...[
          SizedBox(height: AppSpacing.s16),
          Text(
            ProfileCopy.utilitySection,
            style: ReadingTypography.sectionLabel(fontSize: 11).copyWith(
              letterSpacing: 2.2,
              color: OraclyChrome.goldLight.withValues(alpha: 0.58),
            ),
          ),
          SizedBox(height: AppSpacing.s8),
          _ActionCard(
            rows: [
              (
                Icons.settings_outlined,
                ProfileCopy.settingsTitle,
                onOpenSettings,
              ),
            ],
            quiet: true,
          ),
        ],
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.rows, this.quiet = false});

  final List<(IconData, String, VoidCallback)> rows;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return ProfileReferenceCardShell(
      weight: ProfileSurfaceWeight.utility,
      padding: EdgeInsets.zero,
      glowStrength: quiet ? 0.38 : 0.52,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: ColoredBox(
                  color: OraclyChrome.gold.withValues(alpha: 0.14),
                  child: const SizedBox(height: 1, width: double.infinity),
                ),
              ),
            ProfileQuickActionRow(
              icon: rows[i].$1,
              label: rows[i].$2,
              onTap: rows[i].$3,
            ),
          ],
        ],
      ),
    );
  }
}
