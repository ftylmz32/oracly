/// UI helpers: open legal docs / store manage with honest snackbars.
library;

import 'package:flutter/material.dart';

import '../../shared/ui/oracly_snackbar.dart';
import 'legal_copy.dart';
import 'legal_document_kind.dart';
import 'legal_document_launcher.dart';
import 'store_subscription_management.dart';

abstract final class LegalLinkActions {
  LegalLinkActions._();

  static Future<void> openDocument(
    BuildContext context,
    LegalDocumentKind kind,
  ) async {
    final result = await LegalDocumentLauncher.open(kind);
    if (!context.mounted) return;
    switch (result) {
      case LegalOpenResult.opened:
        return;
      case LegalOpenResult.missingUrl:
        OraclySnackBar.show(context, message: LegalCopy.missingUrl);
      case LegalOpenResult.launchFailed:
        OraclySnackBar.show(context, message: LegalCopy.launchFailed);
    }
  }

  static Future<void> openManageSubscription(BuildContext context) async {
    final result = await StoreSubscriptionManagement.open();
    if (!context.mounted) return;
    switch (result) {
      case StoreManageResult.opened:
        return;
      case StoreManageResult.unavailable:
        OraclySnackBar.show(context, message: LegalCopy.manageUnavailable);
      case StoreManageResult.launchFailed:
        OraclySnackBar.show(context, message: LegalCopy.launchFailed);
    }
  }
}