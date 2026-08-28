/// Confirm / affordability dialogs for gem spend — kept out of the guard.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/oracly_navigation_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/ui/oracly_dialog.dart';
import '../../../shared/ui/oracly_snackbar.dart';
import '../copy/gems_copy.dart';
import '../providers/gem_providers.dart';

abstract final class GemSpendUi {
  GemSpendUi._();

  static bool ensureAffordable(
    WidgetRef ref, {
    required BuildContext context,
    required int? cost,
  }) {
    if (cost == null || cost <= 0) return true;
    final wallet = ref.read(gemWalletProvider);
    if (wallet.busy) return false;
    if (!wallet.canSpend(cost)) {
      showInsufficient(context, cost: cost);
      return false;
    }
    return true;
  }

  static Future<bool> confirmCost(
    WidgetRef ref,
    BuildContext context, {
    required int? cost,
    String? reason,
  }) async {
    if (cost == null || cost <= 0) return true;
    final wallet = ref.read(gemWalletProvider);
    final purpose = reason?.trim() ?? '';
    final message = purpose.isEmpty
        ? GemsCopy.confirmBodyWithBalance(
            cost: cost,
            balance: wallet.balance,
          )
        : GemsCopy.confirmBodyPurpose(
            cost: cost,
            balance: wallet.balance,
            reason: purpose,
          );
    final ok = await OraclyDialog.confirm(
      context,
      title: GemsCopy.confirmTitle,
      message: message,
      confirmLabel: GemsCopy.costLabel(cost),
      cancelLabel: GemsCopy.cancel,
    );
    return ok == true;
  }

  static void showInsufficient(
    BuildContext context, {
    required int cost,
  }) {
    OraclySnackBar.error(
      context,
      '${GemsCopy.insufficient}\n${GemsCopy.insufficientCost(cost)}',
      action: SnackBarAction(
        label: GemsCopy.openGemsAction,
        textColor: AppColors.goldLight,
        onPressed: () => OraclyNavigationService.openGems(context),
      ),
    );
  }
}
