/// Compact archive links — Favorite Moments + Discovery Journal.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/navigation/oracly_navigation_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../features/discovery_journal/copy/discovery_journal_copy.dart';
import '../../../features/discovery_journal/providers/discovery_journal_providers.dart';
import '../../../features/favorite_moments/copy/favorite_moments_copy.dart';
import '../../../features/favorite_moments/providers/favorite_moments_providers.dart';
import '../../../shared/widgets/oracly_pressable.dart';
import '../copy/profile_copy.dart';
import 'profile_reference_card_shell.dart';
import 'profile_surface_weight.dart';

class ProfileArchiveCluster extends ConsumerWidget {
  const ProfileArchiveCluster({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moments = ref.watch(favoriteMomentsProvider).valueOrNull ?? const [];
    final journal =
        ref.watch(discoveryJournalEntriesProvider).valueOrNull ?? const [];
    final momentLine = moments.isEmpty
        ? FavoriteMomentsCopy.emptyBody
        : moments.first.quote;
    final journalLine = journal.isEmpty
        ? DiscoveryJournalCopy.emptyTitle
        : '${DiscoveryJournalCopy.badge(journal.first.kind)} · '
            '${journal.first.title}';

    return ProfileReferenceCardShell(
      weight: ProfileSurfaceWeight.utility,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _ArchiveRow(
            icon: Icons.favorite_border_rounded,
            title: FavoriteMomentsCopy.title,
            subtitle: momentLine,
            onTap: () => OraclyNavigationService.openFavoriteMoments(context),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: ColoredBox(
              color: OraclyChrome.gold.withValues(alpha: 0.18),
              child: const SizedBox(height: 1, width: double.infinity),
            ),
          ),
          _ArchiveRow(
            icon: Icons.auto_stories_outlined,
            title: ProfileCopy.journalTitle,
            subtitle: journalLine,
            onTap: () => OraclyNavigationService.openDiscoveryJournal(context),
          ),
        ],
      ),
    );
  }
}

class _ArchiveRow extends StatelessWidget {
  const _ArchiveRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OraclyPressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: OraclyChrome.goldLight.withValues(alpha: 0.88)),
            SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: ReadingTypography.sectionLabel(
                      color: OraclyChrome.goldLight,
                      fontSize: 10,
                    ),
                  ),
                  SizedBox(height: AppSpacing.s4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: ReadingTypography.bodyCore(
                      color: OraclyChrome.cream.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: OraclyChrome.gold.withValues(alpha: 0.36),
            ),
          ],
        ),
      ),
    );
  }
}
