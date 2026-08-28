/// Refined OR header identity — brand mark + calm presence.
///
/// Official mark only (crescent · oracle profile · central star).
/// Compact — never an oversized logo; conversation stays dominant.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/companion_copy.dart';
import 'companion_or_mark.dart';
import 'companion_or_presence.dart';
import 'companion_or_visual.dart';
import 'companion_reference_status_pip.dart';
import 'companion_reference_tokens.dart';

class CompanionReferenceIdentity extends StatelessWidget {
  const CompanionReferenceIdentity({
    super.key,
    this.speaking = false,
    this.presence,
  });

  final bool speaking;
  final CompanionOrPresence? presence;

  @override
  Widget build(BuildContext context) {
    final resolved = presence ??
        (speaking
            ? CompanionOrPresence.speaking
            : CompanionOrVisual.presenceOf(context));
    final status = _statusLine(resolved);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: CompanionOrMark(
            size: CompanionReferenceTokens.identityMark,
            breathe: true,
            presence: resolved,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                CompanionCopy.screenTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ReadingTypography.sectionLabel(
                  fontSize: 12,
                  color: OraclyChrome.goldLight.withValues(alpha: 0.92),
                ).copyWith(letterSpacing: 2.4),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CompanionReferenceStatusPip(presence: resolved),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: OraclyChrome.cream.withValues(
                          alpha: _statusAlpha(resolved),
                        ),
                        fontSize: 11,
                        height: 1.15,
                        letterSpacing: 0.15,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _statusLine(CompanionOrPresence presence) => switch (presence) {
        CompanionOrPresence.thinking => CompanionCopy.presenceThinking,
        CompanionOrPresence.speaking => CompanionCopy.speaking,
        CompanionOrPresence.error => CompanionCopy.offline,
        CompanionOrPresence.idle => CompanionCopy.presence,
      };

  static double _statusAlpha(CompanionOrPresence presence) => switch (presence) {
        CompanionOrPresence.speaking => 0.88,
        CompanionOrPresence.thinking => 0.80,
        CompanionOrPresence.error => 0.62,
        CompanionOrPresence.idle => 0.70,
      };
}
