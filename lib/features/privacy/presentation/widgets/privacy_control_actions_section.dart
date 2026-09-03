/// Destructive privacy actions — confirm before every real delete.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../core/copy/transparency_copy.dart';
import '../../../../features/premium/models/personalization_models.dart';
import '../../../../features/premium/presentation/widgets/settings_tiles.dart';
import '../../../../shared/ui/oracly_dialog.dart';
import '../../../../shared/ui/oracly_snackbar.dart';
import '../../../../shared/widgets/oracly_entrance.dart';
import '../../copy/privacy_control_copy.dart';
import '../../providers/privacy_control_providers.dart';
import '../../services/privacy_data_refresh.dart';
import 'privacy_account_deletion_tile.dart';

class PrivacyControlActionsSection extends ConsumerWidget {
  const PrivacyControlActionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OraclyEntrance.staggered(
          index: 0,
          child: SettingsNavTile(
            icon: Icons.history_rounded,
            title: PrivacyControlCopy.clearHistory,
            subtitle: PrivacyControlCopy.clearHistorySub,
            onTap: () => _confirm(
              context,
              ref,
              title: PrivacyControlCopy.confirmHistoryTitle,
              message: PrivacyControlCopy.confirmHistoryBody,
              action: (ref) async {
                await ref.read(privacyControlServiceProvider).clearDiscoveryHistory();
                PrivacyDataRefresh.afterDiscoveryHistoryClear(ref);
                ref.invalidate(privacyControlSnapshotProvider);
              },
              success: PrivacyControlCopy.successHistory,
            ),
          ),
        ),
        OraclyEntrance.staggered(
          index: 1,
          child: SettingsNavTile(
            icon: Icons.bookmarks_outlined,
            title: PrivacyControlCopy.clearFavorites,
            subtitle: PrivacyControlCopy.clearFavoritesSub,
            onTap: () => _confirm(
              context,
              ref,
              title: PrivacyControlCopy.confirmFavoritesTitle,
              message: PrivacyControlCopy.confirmFavoritesBody,
              action: (ref) async {
                await ref.read(privacyControlServiceProvider).clearFavorites();
                PrivacyDataRefresh.afterFavoritesClear(ref);
                ref.invalidate(privacyControlSnapshotProvider);
              },
              success: PrivacyControlCopy.successFavorites,
            ),
          ),
        ),
        OraclyEntrance.staggered(
          index: 2,
          child: SettingsDestructiveTile(
            icon: Icons.psychology_outlined,
            title: PrivacyControlCopy.resetMemory,
            subtitle: PrivacyControlCopy.resetMemorySub,
            onTap: () => _confirm(
              context,
              ref,
              title: PrivacyControlCopy.confirmMemoryTitle,
              message: PrivacyControlCopy.confirmMemoryBody,
              action: (ref) async {
                await ref.read(privacyControlServiceProvider).resetMemorySummary();
                PrivacyDataRefresh.afterMemoryReset(ref);
                ref.invalidate(privacyControlSnapshotProvider);
              },
              success: PrivacyControlCopy.successMemory,
            ),
          ),
        ),
        OraclyEntrance.staggered(
          index: 3,
          child: _AnalyticsToggle(),
        ),
        const PrivacyAccountDeletionTile(),
      ],
    );
  }

  Future<void> _confirm(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String message,
    required Future<void> Function(WidgetRef ref) action,
    required String success,
  }) async {
    final confirmed = await OraclyDialog.confirm(
      context,
      title: title,
      message: message,
      confirmLabel: 'Sil',
      destructive: true,
    );
    if (confirmed != true || !context.mounted) return;
    await action(ref);
    if (!context.mounted) return;
    OraclySnackBar.show(context, message: success);
  }
}

class _AnalyticsToggle extends ConsumerWidget {
  const _AnalyticsToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull ??
        const PersonalizationSettings();
    return SettingsToggleTile(
      icon: Icons.insights_outlined,
      title: TransparencyCopy.analyticsTitle,
      subtitle: TransparencyCopy.analyticsSubtitle,
      value: settings.analyticsEnabled,
      onChanged: (enabled) async {
        await ref.read(settingsProvider.notifier).saveSettings(
              settings.copyWith(analyticsEnabled: enabled),
            );
        ref.invalidate(privacyControlSnapshotProvider);
      },
    );
  }
}
