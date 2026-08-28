/// Honesty note, saved city, and the next quiet step.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/star_map_polish_copy.dart';
import 'star_map_reference_cta.dart';
import 'star_map_reference_tokens.dart';

class StarMapReferenceStatus extends StatelessWidget {
  const StarMapReferenceStatus({
    super.key,
    required this.hasBirthInfo,
    required this.onPrimary,
    this.cityName,
  });

  final bool hasBirthInfo;
  final VoidCallback onPrimary;
  final String? cityName;

  @override
  Widget build(BuildContext context) {
    final city = cityName?.trim() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          StarMapPolishCopy.whatItIs,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: OraclyChrome.bodySecondary(size: 12).copyWith(
            color: StarMapReferenceTokens.cream.withValues(alpha: 0.70),
            height: 1.36,
          ),
        ),
        if (hasBirthInfo) ...[
          SizedBox(height: AppSpacing.s4),
          Text(
            StarMapPolishCopy.chartReady,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OraclyChrome.bodySecondary(size: 12).copyWith(
              color: StarMapReferenceTokens.cream.withValues(alpha: 0.72),
            ),
          ),
        ],
        if (city.isNotEmpty) ...[
          SizedBox(height: AppSpacing.s4),
          Text(
            city,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ReadingTypography.footnote(
              color: StarMapReferenceTokens.cream.withValues(alpha: 0.62),
            ),
          ),
        ],
        SizedBox(height: AppSpacing.s8),
        StarMapReferenceCta(
          label: hasBirthInfo
              ? StarMapPolishCopy.viewChart
              : StarMapPolishCopy.enterBirthInfo,
          onPressed: onPrimary,
        ),
      ],
    );
  }
}
