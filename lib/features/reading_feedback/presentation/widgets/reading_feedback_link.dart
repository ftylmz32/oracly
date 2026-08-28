/// Quiet action: this interpretation missed the point.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../copy/reading_feedback_copy.dart';
import '../../models/reading_feedback_category.dart';
import '../reading_feedback_opener.dart';

class ReadingFeedbackLink extends ConsumerWidget {
  const ReadingFeedbackLink({
    super.key,
    required this.feature,
    this.retry,
    this.align = Alignment.center,
  });

  final ReadingFeedbackFeature feature;
  final Future<bool> Function()? retry;
  final Alignment align;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Align(
      alignment: align,
      child: Semantics(
        button: true,
        label: ReadingFeedbackCopy.action,
        child: OraclyPressable(
          onTap: () => ReadingFeedbackOpener.open(
            context,
            ref,
            feature: feature,
            retry: retry,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text(
                ReadingFeedbackCopy.action,
                style: ReadingTypography.footnote(
                  color: OraclyChrome.cream.withValues(alpha: 0.62),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
