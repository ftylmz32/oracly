/// Opens discovery comparison when real data supports it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/discovery_journal/models/discovery_journal_entry.dart';
import '../../../shared/ui/oracly_snackbar.dart';
import '../copy/discovery_comparison_copy.dart';
import '../models/discovery_comparison_result.dart';
import '../presentation/screens/discovery_comparison_screen.dart';
import 'discovery_comparison_service.dart';

abstract final class DiscoveryComparisonOpener {
  DiscoveryComparisonOpener._();

  static Future<void> openForEntry(
    BuildContext context,
    WidgetRef ref, {
    required List<DiscoveryJournalEntry> items,
    required DiscoveryJournalEntry current,
  }) async {
    final result = await DiscoveryComparisonService.compareWithPrior(
      ref,
      items: items,
      current: current,
    );
    if (!context.mounted) return;
    if (result == null) {
      OraclySnackBar.show(context, message: DiscoveryComparisonCopy.unavailable);
      return;
    }
    await openResult(context, result);
  }

  static Future<void> openResult(
    BuildContext context,
    DiscoveryComparisonResult result,
  ) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DiscoveryComparisonScreen(result: result),
      ),
    );
  }
}
