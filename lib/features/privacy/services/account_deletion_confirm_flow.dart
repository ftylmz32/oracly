/// Shared destructive account-deletion confirm flow — confirm, reauth,
/// server-delete-first, then identity delete. The ONLY place that may
/// authorize actually deleting the account; a corrupt local marker alone
/// must never reach this without the user's own explicit tap here.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/auth/account_deletion_owner_bootstrap.dart';
import '../../../core/auth/account_deletion_pending_state.dart';
import '../../../core/auth/presentation/account_deletion_pending_screen.dart';
import '../../../shared/ui/oracly_dialog.dart';
import '../../../shared/ui/oracly_snackbar.dart';
import '../copy/privacy_control_copy.dart';
import '../providers/privacy_control_providers.dart';
import '../services/account_deletion_reauth_prompt.dart';
import '../services/privacy_data_refresh.dart';

abstract final class AccountDeletionConfirmFlow {
  AccountDeletionConfirmFlow._();

  /// Confirmation dialog, then (if linked) a reauth prompt, then the real
  /// server-delete-first deletion. Zero destructive work happens if the
  /// user cancels either step.
  static Future<void> confirmAndDelete(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await OraclyDialog.confirm(
      context,
      title: PrivacyControlCopy.confirmDeleteTitle,
      message: PrivacyControlCopy.confirmDeleteBody,
      confirmLabel: PrivacyControlCopy.confirmDeleteAction,
      destructive: true,
    );
    if (confirmed != true || !context.mounted) return;

    final auth = ref.read(authServiceProvider);
    final reauth = auth.isCurrentUserAnonymous
        ? null
        : await AccountDeletionReauthPrompt.collect(context, auth);
    if (!auth.isCurrentUserAnonymous && reauth == null) {
      // Cancelled provider/password prompt — zero destructive work.
      return;
    }
    if (!context.mounted) return;

    final result = await ref
        .read(accountDeletionServiceProvider)
        .deleteAccountAndWipeLocalData(reauth: reauth);
    if (!context.mounted) return;

    if (result.isFailure) {
      if (AccountDeletionPendingState.isBlocked ||
          AccountDeletionPendingState.isFinalizing) {
        OraclySnackBar.show(
          context,
          message: AccountDeletionPendingState.isFinalizing
              ? PrivacyControlCopy.deleteFinalizingBody
              : PrivacyControlCopy.deletePendingBody,
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) => const AccountDeletionPendingScreen(),
          ),
          (_) => false,
        );
      } else {
        OraclySnackBar.show(
          context,
          message: result.errorOrNull?.message ??
              PrivacyControlCopy.confirmDeleteBody,
        );
      }
      return;
    }

    PrivacyDataRefresh.afterAccountSwitch(ref);
    await AccountDeletionOwnerBootstrap.installReadingPushIfClear(
      ProviderScope.containerOf(context, listen: false),
    );
    if (!context.mounted) return;
    ref.invalidate(privacyControlSnapshotProvider);
    OraclySnackBar.show(context, message: PrivacyControlCopy.successDelete);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
