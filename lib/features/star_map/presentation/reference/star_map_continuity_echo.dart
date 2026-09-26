/// Verified archive echo — labels only, never provenance IDs.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/design_system/oracly_soft_reveal.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../result/yildizname_continuity_presentation.dart';
import 'star_map_archive_separator.dart';

class StarMapContinuityEcho extends StatelessWidget {
  const StarMapContinuityEcho({
    super.key,
    required this.continuity,
    this.showSeparator = true,
  });

  final YildiznameContinuityPresentation continuity;
  final bool showSeparator;

  @override
  Widget build(BuildContext context) {
    if (continuity.isEmpty) return const SizedBox.shrink();
    return OraclySoftReveal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showSeparator) const StarMapArchiveSeparator(),
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Semantics(
              container: true,
              explicitChildNodes: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      continuity.heading,
                      textAlign: TextAlign.center,
                      style: ReadingTypography.sectionLabel(
                        color:
                            OraclyChrome.goldPrimary.withValues(alpha: 0.92),
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    continuity.body,
                    textAlign: TextAlign.center,
                    style: ReadingTypography.bodySmall(
                      color: OraclyChrome.cream.withValues(alpha: 0.72),
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  for (final label in continuity.labels)
                    Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Semantics(
                        label: label,
                        child: ExcludeSemantics(
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: ReadingTypography.body(
                              color:
                                  OraclyChrome.cream.withValues(alpha: 0.88),
                            ).copyWith(fontSize: 15, height: 1.45),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
