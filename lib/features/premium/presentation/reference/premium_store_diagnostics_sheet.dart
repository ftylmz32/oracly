/// Hidden support sheet — safe store diagnostics a tester can copy.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/copy/premium_copy.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/ui/oracly_bottom_sheet.dart';
import '../../../../shared/ui/oracly_sheet_action.dart';
import '../../../../shared/ui/oracly_snackbar.dart';
import '../../models/store_catalog_snapshot.dart';
import '../../services/premium_purchase_port.dart';
import '../../services/store_diagnostics_formatter.dart';
import '../../services/store_purchase_stream_diagnostics.dart';

String premiumStoreDiagnosticsText(PremiumPurchasePort port) {
  final catalog = port is StoreCatalogDiagnosticsSource
      ? (port as StoreCatalogDiagnosticsSource).catalogSnapshot
      : null;
  return StoreDiagnosticsFormatter.format(
    catalog: catalog,
    stream: StorePurchaseStreamDiagnostics.recent,
  );
}

Future<void> showPremiumStoreDiagnostics(
  BuildContext context,
  PremiumPurchasePort port,
) {
  final text = premiumStoreDiagnosticsText(port);
  return OraclyBottomSheet.show<void>(
    context,
    title: PremiumCopy.storeDiagnosticsTitle,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: SelectableText(
            text,
            style: ReadingTypography.metadata(
              color: OraclyChrome.cream.withValues(alpha: 0.86),
            ).copyWith(fontFamily: 'monospace', height: 1.5),
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        OraclySheetAction(
          label: PremiumCopy.storeDiagnosticsCopy,
          icon: Icons.copy_rounded,
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: text));
            if (!context.mounted) return;
            OraclySnackBar.success(context, PremiumCopy.storeDiagnosticsCopied);
          },
        ),
      ],
    ),
  );
}
