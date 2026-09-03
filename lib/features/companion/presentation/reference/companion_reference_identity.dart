/// Luna header identity -- centered gold title with sparkle marks.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/companion_copy.dart';
import 'companion_or_presence.dart';

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
    final status = switch (presence) {
      CompanionOrPresence.thinking => CompanionCopy.presenceThinking,
      CompanionOrPresence.speaking => CompanionCopy.speaking,
      CompanionOrPresence.error => CompanionCopy.offline,
      _ => CompanionCopy.guideSubtitle,
    };
    final sparkle = Icon(
      Icons.auto_awesome,
      size: 11,
      color: OraclyChrome.goldLight.withValues(alpha: 0.88),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            sparkle,
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                CompanionCopy.screenTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: ReadingTypography.sectionLabel(
                  fontSize: 14,
                  color: OraclyChrome.goldLight.withValues(alpha: 0.96),
                ).copyWith(letterSpacing: 3.0),
              ),
            ),
            const SizedBox(width: 8),
            sparkle,
          ],
        ),
        const SizedBox(height: 3),
        Text(
          status,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: ReadingTypography.micro(
            color: OraclyChrome.goldLight.withValues(alpha: 0.72),
          ).copyWith(fontSize: 11, height: 1.15),
        ),
      ],
    );
  }
}
