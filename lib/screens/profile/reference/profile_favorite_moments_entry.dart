/// Profile entry — preview saved moments collection.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/navigation/oracly_navigation_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../features/favorite_moments/copy/favorite_moments_copy.dart';
import '../../../features/favorite_moments/presentation/widgets/favorite_moment_visual.dart';
import '../../../features/favorite_moments/providers/favorite_moments_providers.dart';
import 'profile_reference_card_shell.dart';
import 'profile_surface_weight.dart';

class ProfileFavoriteMomentsEntry extends ConsumerWidget {
  const ProfileFavoriteMomentsEntry({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(favoriteMomentsProvider).valueOrNull ?? const [];
    final preview = items.isEmpty
        ? FavoriteMomentsCopy.emptyBody
        : items.first.quote;
    final lead = items.isEmpty ? null : items.first;

    return ProfileReferenceCardShell(
      weight: ProfileSurfaceWeight.utility,
      onTap: () => OraclyNavigationService.openFavoriteMoments(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            FavoriteMomentsCopy.title,
            style: ReadingTypography.sectionLabel(
              color: OraclyChrome.goldLight,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (lead != null) ...[
                FavoriteMomentVisual(moment: lead, size: 40),
                const SizedBox(width: AppSpacing.s12),
              ],
              Expanded(
                child: Text(
                  preview,
                  style: ReadingTypography.bodyCore(
                    color: OraclyChrome.cream.withValues(alpha: 0.78),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
