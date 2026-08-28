/// Copies sanitized insight text and confirms quietly.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/ui/oracly_snackbar.dart';
import 'insight_copy_strings.dart';
import 'insight_copy_text.dart';

abstract final class InsightCopyAction {
  InsightCopyAction._();

  static Future<void> copy(BuildContext context, String raw) async {
    final text = InsightCopyText.clean(raw);
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    OraclySnackBar.show(
      context,
      message: InsightCopyStrings.copied,
      duration: const Duration(milliseconds: 1800),
    );
  }
}
