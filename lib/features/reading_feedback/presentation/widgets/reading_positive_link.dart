/// Quiet positive quality signal — metadata only.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/quality/quality_feature.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/ui/oracly_snackbar.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../../quality_loop/providers/quality_loop_providers.dart';
import '../../copy/reading_feedback_copy.dart';

class ReadingPositiveLink extends ConsumerWidget {
  const ReadingPositiveLink({
    super.key,
    required this.feature,
    this.align = Alignment.center,
  });

  final QualityFeature feature;
  final Alignment align;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Align(
      alignment: align,
      child: Semantics(
        button: true,
        label: ReadingFeedbackCopy.positive,
        child: OraclyPressable(
          onTap: () => _send(context, ref),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text(
                ReadingFeedbackCopy.positive,
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

  Future<void> _send(BuildContext context, WidgetRef ref) async {
    await ref.read(qualitySignalRecorderProvider).positive(feature);
    ref.read(analyticsServiceProvider).logQualitySignal(
          feature: feature,
          signal: 'positive',
        );
    if (!context.mounted) return;
    OraclySnackBar.show(context, message: ReadingFeedbackCopy.positiveThanks);
  }
}
