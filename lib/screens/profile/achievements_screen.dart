/// OR-1120 — Full achievements gallery.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/models/achievement.dart';
import '../../core/copy/resilience_copy.dart';
import '../../core/design_system/app_icons.dart';
import '../../core/design_system/oracly_header_action.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/premium/models/achievement_models.dart' as ui;
import '../../features/premium/presentation/widgets/achievement_badge.dart';
import '../../features/premium/presentation/widgets/premium_background.dart';
import '../../features/premium/presentation/widgets/settings_tiles.dart';
import '../../shared/widgets/oracly_error_state.dart';
import '../../shared/widgets/oracly_skeleton_loader.dart';
import 'achievements_providers.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  ui.Achievement _toUi(AchievementModel model) {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const PremiumBackground(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.black.withValues(alpha: 0.45),
                leading: Align(
                  child: OraclyHeaderAction(
                    icon: AppIcons.back,
                    label: OraclyL10n.t(L10nKeys.back),
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ),
                title: Text(OraclyL10n.t('achievements.title')),
                centerTitle: true,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: achievementsAsync.when(
                    loading: () => OraclySkeletonLoader(
                      message: ResilienceCopy.achievementsLoading,
                    ),
                    error: (e, _) => OraclyErrorState(
                      message: ResilienceCopy.genericLoadFailed,
                      onRetry: () => ref.invalidate(achievementsProvider),
                    ),
                    data: (achievements) {
                      final unlocked = achievements
                          .where((a) => a.unlocked)
                          .length;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SettingsSectionHeader(
                            title: OraclyL10n.t('achievements.progress'),
                          ),
                          Text(
                            '$unlocked / ${achievements.length} başarım açıldı',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          SizedBox(height: AppSpacing.md),
                          AchievementsGrid(
                            achievements: achievements.map(_toUi).toList(),
                            compact: false,
                          ),
                          SizedBox(height: AppSpacing.xxl),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
