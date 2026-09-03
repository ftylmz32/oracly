/// Keşif Günlüğü compact bridge — latest real record only.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../features/discovery_journal/copy/discovery_journal_copy.dart';
import '../../../features/discovery_journal/models/discovery_journal_entry.dart';
import '../../../features/discovery_journal/models/discovery_journal_kind.dart';
import '../../../features/discovery_journal/providers/discovery_journal_providers.dart';
import '../copy/profile_copy.dart';
import 'profile_reference_card_shell.dart';

class ProfileReferenceDiscoveryBridge extends ConsumerWidget {
  const ProfileReferenceDiscoveryBridge({super.key, required this.onTap});

  final VoidCallback onTap;

  static IconData _iconFor(DiscoveryJournalEntry entry) => switch (entry.kind) {
    DiscoveryJournalKind.dream => Icons.nights_stay_rounded,
    DiscoveryJournalKind.coffee => Icons.local_cafe_rounded,
    DiscoveryJournalKind.palm => Icons.pan_tool_outlined,
    DiscoveryJournalKind.companion => Icons.forum_outlined,
    DiscoveryJournalKind.tarot => Icons.auto_stories_rounded,
    DiscoveryJournalKind.astrology => Icons.auto_awesome_rounded,
    DiscoveryJournalKind.starMap => Icons.star_rounded,
    DiscoveryJournalKind.dailyMessage => Icons.wb_twilight_outlined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final items = ref.watch(discoveryJournalEntriesProvider).valueOrNull ?? [];
    final latest = items.isEmpty ? null : items.first;

    return ProfileReferenceCardShell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ProfileCopy.journalTitle,
              style: ReadingTypography.sectionLabel(color: palette.goldLight),
            ),
            SizedBox(height: AppSpacing.s4),
            Text(
              ProfileCopy.journalBridgeSubtitle,
              style: ReadingTypography.body(
                color: palette.textSecondary.withValues(alpha: 0.78),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: AppSpacing.s12),
            if (latest == null)
              Text(
                DiscoveryJournalCopy.emptyTitle,
                style: ReadingTypography.body(
                  color: palette.textSecondary.withValues(alpha: 0.78),
                ),
              )
            else ...[
              Row(
                children: [
                  Icon(
                    _iconFor(latest),
                    size: 18,
                    color: palette.goldLight.withValues(alpha: 0.88),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${DiscoveryJournalCopy.badge(latest.kind)} · '
                          '${latest.title}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: palette.goldLight.withValues(alpha: 0.92),
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          latest.dateLabel,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.s12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  ProfileCopy.journalBridgeOpenCta,
                  style: ReadingTypography.bodyCore(
                    color: palette.goldLight.withValues(alpha: 0.92),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
