/// Account deletion tile — destructive confirm, reauth, remote-first wipe.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/premium/presentation/widgets/settings_tiles.dart';
import '../../../../shared/widgets/oracly_entrance.dart';
import '../../copy/privacy_control_copy.dart';
import '../../services/account_deletion_confirm_flow.dart';

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
        onTap: () => AccountDeletionConfirmFlow.confirmAndDelete(context, ref),
      ),
    );
  }
}
