/// Gems ledger empty — small photoreal plate, one honest sentence.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_empty_atmosphere.dart';
import '../../copy/gems_copy.dart';

class GemsHistoryEmpty extends StatelessWidget {
  const GemsHistoryEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const OraclyEmptyAtmosphere(
          assetPath: AppAssets.premiumGemstone,
          size: 64,
          warm: true,
        ),
        SizedBox(width: AppSpacing.s12),
        Expanded(
          child: Text(
            GemsCopy.historyEmpty,
            style: ReadingTypography.bodyCore(
              color: OraclyChrome.cream.withValues(alpha: 0.74),
            ),
          ),
        ),
      ],
    );
  }
}
