/// Thinking — quiet breath around the living core. No spinner.
library;

import 'package:flutter/material.dart';

import '../../../../core/accessibility/oracly_a11y.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/companion_copy.dart';
import 'companion_or_living_core.dart';
import 'companion_or_presence.dart';
import 'companion_reference_tokens.dart';

class CompanionReferenceThinking extends StatelessWidget {
  const CompanionReferenceThinking({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: CompanionCopy.thinking,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          CompanionReferenceTokens.screenHorizontal,
          AppSpacing.s8,
          CompanionReferenceTokens.screenHorizontal,
          AppSpacing.s4,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ExcludeSemantics(
                child: CompanionOrLivingCore(
                  size: CompanionReferenceTokens.orMark + 10,
                  compact: true,
                  breathe: true,
                  presence: CompanionOrPresence.thinking,
                ),
              ),
              const SizedBox(width: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: OraclyChrome.gold.withValues(alpha: 0.18),
                      width: 0.6,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    CompanionCopy.thinking,
                    style: ReadingTypography.micro(
                      color: OraclyA11y.goldReadable(OraclyChrome.goldLight),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
