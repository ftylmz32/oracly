/// Calm OR session status — never a full-screen lock.
library;

import 'package:flutter/material.dart';

import '../../../../core/accessibility/oracly_a11y.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_text_action.dart';
import '../../copy/companion_copy.dart';
import '../../models/or_session_presentation.dart';
import 'companion_reference_tokens.dart';

class CompanionOrSessionStrip extends StatelessWidget {
  const CompanionOrSessionStrip({
    super.key,
    required this.presentation,
    this.onRetry,
  });

  final OrSessionPresentation presentation;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (!presentation.showStatusStrip) return const SizedBox.shrink();

    final connecting = presentation.connecting;
    final soft = presentation.softStatus;
    final line = presentation.statusLine!;

    return Semantics(
      liveRegion: true,
      label: line,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          CompanionReferenceTokens.screenHorizontal,
          AppSpacing.s8,
          CompanionReferenceTokens.screenHorizontal,
          0,
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: connecting
                      ? OraclyA11y.goldReadable(OraclyChrome.goldLight)
                      : OraclyChrome.cream.withValues(
                          alpha: soft
                              ? OraclyA11y.hintCream
                              : OraclyA11y.secondaryCream,
                        ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                line,
                style: ReadingTypography.bodyCore(
                  color: OraclyChrome.cream.withValues(
                    alpha: connecting
                        ? OraclyA11y.secondaryCream
                        : soft
                            ? OraclyA11y.hintCream
                            : OraclyA11y.secondaryCream,
                  ),
                ).copyWith(fontSize: 12, height: 1.2),
              ),
            ),
            if (presentation.canRetry && onRetry != null)
              OraclyTextAction(
                label: CompanionCopy.retry,
                emphasized: true,
                onPressed: onRetry,
              ),
          ],
        ),
      ),
    );
  }
}
