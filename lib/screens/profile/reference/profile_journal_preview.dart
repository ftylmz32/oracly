/// Profile journal preview — real persisted records only.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/oracly_navigation_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../features/discovery_journal/copy/discovery_journal_copy.dart';
import '../../../features/discovery_journal/models/discovery_journal_entry.dart';
import '../../../features/discovery_journal/providers/discovery_journal_providers.dart';
import '../copy/profile_copy.dart';
import 'profile_reference_card_shell.dart';

class ProfileJournalPreview extends ConsumerWidget {
  const ProfileJournalPreview({super.key});

  static const previewCount = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final items =
        ref.watch(discoveryJournalEntriesProvider).valueOrNull ??
        const <DiscoveryJournalEntry>[];
    final preview = items.take(previewCount).toList();
    return Semantics(
      button: true,
      label: ProfileCopy.journalTitle,
      child: ProfileReferenceCardShell(
        onTap: () => OraclyNavigationService.openDiscoveryJournal(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ProfileCopy.journalTitle,
                style: ReadingTypography.sectionLabel(color: palette.goldLight),
              ),
              SizedBox(height: AppSpacing.sm),
              if (preview.isEmpty)
                Text(
                  DiscoveryJournalCopy.emptyTitle,
                  style: ReadingTypography.body(color: palette.textSecondary),
                )
              else
                for (var i = 0; i < preview.length; i++) ...[
                  if (i > 0) SizedBox(height: AppSpacing.s8),
                  Text(
                    '${DiscoveryJournalCopy.badge(preview[i].kind)} · '
                    '${preview[i].title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ReadingTypography.bodyCore(
                      color: palette.goldLight.withValues(alpha: 0.90),
                    ),
                  ),
                  Text(
                    preview[i].dateLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                ],
            ],
          ),
        ),
      ),
    );
  }
}
