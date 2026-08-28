/// Favorite Moments — thumbnail strip of real saved visuals.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/navigation/oracly_navigation_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../features/favorite_moments/copy/favorite_moments_copy.dart';
import '../../../features/favorite_moments/presentation/widgets/favorite_moment_visual.dart';
import '../../../features/favorite_moments/providers/favorite_moments_providers.dart';
import '../../../shared/widgets/oracly_empty_atmosphere.dart';
import '../../../shared/widgets/oracly_pressable.dart';
import 'profile_chamber_chrome.dart';
import 'profile_reference_card_shell.dart';
import 'profile_surface_weight.dart';

class ProfileMomentsStrip extends ConsumerWidget {
  const ProfileMomentsStrip({super.key});

  static const double _thumb = 68;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moments = ref.watch(favoriteMomentsProvider).valueOrNull ?? const [];
    return ProfileReferenceCardShell(
      weight: ProfileSurfaceWeight.story,
      glowStrength: 0.70,
      onTap: () => OraclyNavigationService.openFavoriteMoments(context),
      child: ProfileChamberRail(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileChamberTitle(title: FavoriteMomentsCopy.title),
            SizedBox(height: ProfileChamberGap.afterTitle),
            if (moments.isEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const OraclyEmptyAtmosphere(
                    assetPath: AppAssets.dailyMoonPhotoreal,
                    size: 56,
                  ),
                  SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Text(
                      FavoriteMomentsCopy.emptyTitle,
                      softWrap: true,
                      style: ReadingTypography.body(
                        color: OraclyChrome.cream.withValues(alpha: 0.76),
                      ),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                height: _thumb,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: moments.length.clamp(0, 12),
                  separatorBuilder: (_, _) => SizedBox(width: AppSpacing.s8),
                  itemBuilder: (context, i) {
                    return OraclyPressable(
                      onTap: () =>
                          OraclyNavigationService.openFavoriteMoments(context),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: FavoriteMomentVisual(
                          moment: moments[i],
                          size: _thumb,
                        ),
                      ),
                    );
                  },
                ),
              ),
            SizedBox(height: ProfileChamberGap.beforeCta),
            ProfileChamberCta(label: FavoriteMomentsCopy.openCta),
          ],
        ),
      ),
    );
  }
}
