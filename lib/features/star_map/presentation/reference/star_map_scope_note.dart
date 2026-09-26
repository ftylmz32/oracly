/// Archive scope note — what the reading rests on, kept quiet and readable.
///
/// A hairline brass rail beside two calm lines. Not a warning banner, not a
/// card, never interactive: the truth is simply written where it is read.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../result/yildizname_result_presentation.dart';

class StarMapScopeNote extends StatelessWidget {
  const StarMapScopeNote({super.key, required this.disclosure});

  final YildiznameScopeDisclosure disclosure;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 1,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        OraclyChrome.goldLight.withValues(alpha: 0.55),
                        OraclyChrome.gold.withValues(alpha: 0.10),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        disclosure.kicker,
                        style: ReadingTypography.metadata(
                          color: OraclyChrome.goldLight.withValues(alpha: 0.78),
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      disclosure.body,
                      style: ReadingTypography.bodySmall(
                        color: OraclyChrome.cream.withValues(alpha: 0.72),
                      ).copyWith(fontSize: 13.5, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
