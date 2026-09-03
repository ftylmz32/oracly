/// Account deletion tile — destructive confirm, remote-first, honest errors.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/premium/presentation/widgets/settings_tiles.dart';
import '../../../../shared/ui/oracly_dialog.dart';
import '../../../../shared/ui/oracly_snackbar.dart';
import '../../../../shared/widgets/oracly_entrance.dart';
import '../../copy/privacy_control_copy.dart';
import '../../providers/privacy_control_providers.dart';
import '../../services/privacy_data_refresh.dart';

class PrivacyAccountDeletionTile extends ConsumerWidget {
  const PrivacyAccountDeletionTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OraclyEntrance.staggered(
      index: 4,
      child: SettingsDestructiveTile(
        icon: Icons.person_off_outlined,
        title: PrivacyControlCopy.deleteAccount,
        subtitle: PrivacyControlCopy.deleteAccountSub,
        onTap: () => _confirmAndDelete(context, ref),
      ),
    );
  }

  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await OraclyDialog.confirm(
      context,
      title: PrivacyControlCopy.confirmDeleteTitle,
      message: PrivacyControlCopy.confirmDeleteBody,
      confirmLabel: PrivacyControlCopy.confirmDeleteAction,
      destructive: true,
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref
        .read(accountDeletionServiceProvider)
        .deleteAccountAndWipeLocalData();
    if (!context.mounted) return;

    if (result.isFailure) {
      OraclySnackBar.show(
        context,
        message: result.errorOrNull?.message ??
            PrivacyControlCopy.confirmDeleteBody,
      );
      return;
    }

    PrivacyDataRefresh.afterAccountSwitch(ref);
    ref.invalidate(privacyControlSnapshotProvider);
    OraclySnackBar.show(context, message: PrivacyControlCopy.successDelete);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}