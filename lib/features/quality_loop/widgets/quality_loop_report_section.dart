/// Quiet quality summary — metadata only, never private text.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../premium/presentation/widgets/settings_tiles.dart';
import '../copy/quality_loop_copy.dart';
import '../providers/quality_loop_providers.dart';
import '../../privacy/presentation/widgets/privacy_control_summary_row.dart';

class QualityLoopReportSection extends ConsumerWidget {
  const QualityLoopReportSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(qualityLoopReportProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSectionHeader(title: QualityLoopCopy.section),
        if (report.empty)
          PrivacyControlSummaryRow(
            label: QualityLoopCopy.section,
            value: QualityLoopCopy.empty,
          )
        else ...[
          PrivacyControlSummaryRow(
            label: QualityLoopCopy.problem,
            value: QualityLoopCopy.problemValue(report),
          ),
          PrivacyControlSummaryRow(
            label: QualityLoopCopy.issue,
            value: QualityLoopCopy.issueValue(report),
          ),
          PrivacyControlSummaryRow(
            label: QualityLoopCopy.success,
            value: QualityLoopCopy.successValue(report),
          ),
        ],
        SizedBox(height: AppSpacing.md),
      ],
    );
  }
}
