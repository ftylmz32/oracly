/// One saved moment fragment — editorial tile on the archive timeline.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/design_system/oracly_glass_card.dart';
import '../../../../core/design_system/oracly_header_action.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../discovery_journal/presentation/widgets/discovery_journal_badge.dart';
import '../../copy/favorite_moments_copy.dart';
import '../../models/favorite_moment.dart';
import 'favorite_moment_visual.dart';

class FavoriteMomentTile extends StatelessWidget {
  const FavoriteMomentTile({
    super.key,
    required this.moment,
    required this.onTap,
    required this.onRemove,
  });

  final FavoriteMoment moment;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final feature = FavoriteMomentsCopy.featureLabel(moment);
    return Semantics(
      button: true,
      label: '$feature, ${moment.dateLabel}, ${moment.quote}',
      child: OraclyGlassCard(
        onTap: onTap,
        elevated: true,
        glowStrength: 0.64,
        padding: const EdgeInsets.all(AppSpacing.s12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FavoriteMomentVisual(moment: moment),
            const SizedBox(width: AppSpacing.s12),
            Expanded(child: _Body(moment: moment, onRemove: onRemove)),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.moment, required this.onRemove});

  final FavoriteMoment moment;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            DiscoveryJournalBadge(kind: moment.source.journalKind),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: Text(
                moment.dateLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ReadingTypography.footnote(
                  color: OraclyChrome.goldLight.withValues(alpha: 0.72),
                ),
              ),
            ),
            Semantics(
              button: true,
              label: FavoriteMomentsCopy.remove,
              child: OraclyHeaderAction(
                icon: Icons.bookmark_remove_outlined,
                label: FavoriteMomentsCopy.remove,
                size: 36,
                iconSize: 18,
                onTap: onRemove,
              ),
            ),
          ],
        ),
        if (moment.visualLabel?.trim().isNotEmpty ?? false) ...[
          const SizedBox(height: AppSpacing.s4),
          Text(
            moment.visualLabel!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ReadingTypography.sectionLabel(
              color: OraclyChrome.cream.withValues(alpha: 0.88),
              fontSize: 11,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.s8),
        Text(
          moment.quote,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: ReadingTypography.body(
            color: OraclyChrome.cream.withValues(alpha: 0.78),
          ),
        ),
      ],
    );
  }
}
