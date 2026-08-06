/// OR-1100 — Premium profile experience with Riverpod.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import '../../core/copy/resilience_copy.dart';
import '../../core/domain/models/achievement.dart';
import '../../core/domain/models/user_profile.dart';
import '../../core/navigation/oracly_navigation_service.dart';
import '../../core/navigation/universe/universe_map_sheet.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/ui/oracly_dialog.dart';
import '../../features/premium/models/achievement_models.dart' as ui;
import '../../features/premium/models/personalization_models.dart';
import '../../features/premium/presentation/widgets/achievement_badge.dart';
import '../../features/premium/presentation/widgets/premium_background.dart';
import '../../features/premium/presentation/widgets/profile_hero_section.dart';
import '../../features/premium/presentation/widgets/settings_tiles.dart';
import '../../shared/widgets/oracly_error_state.dart';
import '../../shared/widgets/oracly_skeleton_loader.dart';
import '../../core/widgets/oracly_signature_motifs.dart';
import 'profile_menu_section.dart';

final achievementsProvider = FutureProvider<List<AchievementModel>>((ref) {
  return ref.watch(userRepositoryProvider).getAchievements();
});

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Future<void> _editName(String current) async {
    final name = await OraclyDialog.prompt(
      context,
      title: 'İsim',
      hint: 'Adın',
      initial: current,
      confirmLabel: 'Kaydet',
    );
    if (name != null && name.trim().isNotEmpty) {
      await ref.read(userProfileProvider.notifier).saveName(name.trim());
    }
  }

  PersonalizationSettings _toSettings(UserProfileModel profile) {
    return PersonalizationSettings(
      isPremium: profile.isPremium,
      currentStreak: profile.currentStreak,
      totalReadings: profile.totalReadings,
      spiritualLevel: profile.spiritualLevel,
      favoriteDeck: profile.favoriteDeckId,
    );
  }

  ui.Achievement _toUiAchievement(AchievementModel model) {
    final id = ui.AchievementId.values.firstWhere(
      (e) => e.key == model.key,
      orElse: () => ui.AchievementId.firstReading,
    );
    return ui.Achievement(
      id: id,
      unlocked: model.unlocked,
      icon: model.icon,
      unlockedAt: model.unlockedAt,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final achievementsAsync = ref.watch(achievementsProvider);
    final master = Curves.easeOutCubic.transform(_entrance.value);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const PremiumBackground(),
          const OraclySignatureCornerOrnaments(
            inset: 18,
            size: 18,
          ),
          profileAsync.when(
            loading: () => const OraclySkeletonLoader(
              message: ResilienceCopy.profileLoading,
            ),
            error: (e, _) => OraclyErrorState(
              title: ResilienceCopy.errorTitle,
              message: ResilienceCopy.profileLoadFailed,
              onRetry: () => ref.invalidate(userProfileProvider),
            ),
            data: (UserProfileModel profile) {
              final settings = settingsAsync.value ?? _toSettings(profile);
              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: Colors.black.withValues(alpha: 0.45),
                    title: Text(
                      'Yolculuk',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.goldLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    centerTitle: true,
                    actions: [
                      IconButton(
                        onPressed: () => UniverseMapSheet.open(context),
                        icon: Icon(
                          Icons.map_outlined,
                          color: AppColors.goldLight.withValues(alpha: 0.88),
                        ),
                        tooltip: 'Evren Haritası',
                      ),
                      IconButton(
                        onPressed: () =>
                            OraclyNavigationService.openSettings(context),
                        icon: Icon(
                          Icons.settings_outlined,
                          color: AppColors.goldLight.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: AppSpacing.sm),
                        ProfileHeroSection(
                          name: profile.name,
                          settings: settings,
                          entrance: master,
                          onEditName: () => _editName(profile.name),
                          onPremiumTap: () =>
                              OraclyNavigationService.openPremium(context),
                        ),
                        const ProfileMenuSection(),
                        const SettingsSectionHeader(title: 'Başarımlar'),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          child: achievementsAsync.when(
                            loading: () => const OraclySkeletonLoader(
                              lines: 2,
                              message: ResilienceCopy.achievementsLoading,
                            ),
                            error: (_, _) => const SizedBox.shrink(),
                            data: (achievements) => AchievementsGrid(
                              achievements: achievements
                                  .map(_toUiAchievement)
                                  .toList(),
                              compact: true,
                            ),
                          ),
                        ),
                        SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
