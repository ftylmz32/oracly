/// Opens feedback, records metadata, optionally retries without gems.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../shared/ui/oracly_snackbar.dart';
import '../../../core/reading_version/copy/reading_version_copy.dart';
import '../copy/reading_feedback_copy.dart';
import '../models/reading_feedback_category.dart';
import '../providers/reading_feedback_providers.dart';
import 'widgets/reading_feedback_sheet.dart';

abstract final class ReadingFeedbackOpener {
  ReadingFeedbackOpener._();

  static Future<void> open(
    BuildContext context,
    WidgetRef ref, {
    required ReadingFeedbackFeature feature,
    Future<bool> Function()? retry,
  }) async {
    final result = await showReadingFeedbackSheet(
      context: context,
      canRetry: retry != null,
    );
    if (result == null || !context.mounted) return;
    final service = ref.read(readingFeedbackServiceProvider);

    if (result.choice == ReadingFeedbackChoice.send || retry == null) {
      await service.record(
        feature: feature,
        category: result.category,
        ok: true,
      );
      ref.read(analyticsServiceProvider).logQualitySignal(
            feature: feature,
            signal: 'negative',
            issue: result.category.wire,
          );
      if (!context.mounted) return;
      OraclySnackBar.show(context, message: ReadingFeedbackCopy.thanks);
      return;
    }

    OraclySnackBar.show(context, message: ReadingFeedbackCopy.retrying);
    ref.read(analyticsServiceProvider).logQualitySignal(
          feature: feature,
          signal: 'retry',
          issue: result.category.wire,
        );
    try {
      final changed = await service.retryWithoutCharge(
        feature: feature,
        category: result.category,
        retry: retry,
      );
      if (!context.mounted) return;
      OraclySnackBar.show(
        context,
        message:
            changed ? ReadingFeedbackCopy.retryOk : ReadingVersionCopy.unchanged,
      );
    } catch (_) {
      if (!context.mounted) return;
      OraclySnackBar.show(
        context,
        message: ReadingFeedbackCopy.retryFail,
      );
    }
  }
}
