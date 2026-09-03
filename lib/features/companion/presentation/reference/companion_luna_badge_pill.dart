/// Always-here badge — moon glyph inside a hairline gold pill.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/companion_copy.dart';

class CompanionLunaBadgePill extends StatelessWidget {
  const CompanionLunaBadgePill({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: OraclyChrome.gold.withValues(alpha: 0.42),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 9 : 11,
          vertical: compact ? 4 : 5,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.nightlight_round,
              size: 11,
              color: OraclyChrome.goldLight.withValues(alpha: 0.82),
            ),
            const SizedBox(width: 6),
            Text(
              CompanionCopy.introBadge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ReadingTypography.micro(
                color: OraclyChrome.goldLight.withValues(alpha: 0.86),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
