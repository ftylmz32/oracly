/// Quiet archive provenance — historical reopen only, never a CTA.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../result/yildizname_historical_status.dart';

class StarMapHistoricalStatus extends StatelessWidget {
  const StarMapHistoricalStatus({super.key, required this.status});

  final YildiznameHistoricalStatus status;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        container: true,
        label: status.line,
        excludeSemantics: true,
        child: Text(
          status.line,
          style: ReadingTypography.metadata(
            color: OraclyChrome.goldLight.withValues(alpha: 0.72),
          ),
        ),
      ),
    );
  }
}
