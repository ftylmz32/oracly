/// Compact OR invite — conversation, not a greeting card.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/companion_copy.dart';

class CompanionReferenceWelcome extends StatelessWidget {
  const CompanionReferenceWelcome({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('OR', style: OraclyChrome.engravedTitle(size: 18)),
        const SizedBox(height: 8),
        Text(
          CompanionCopy.welcomeTitle,
          style: ReadingTypography.opening(
            color: OraclyChrome.goldLight.withValues(alpha: 0.94),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          CompanionCopy.welcomeBody,
          style: ReadingTypography.body(
            color: OraclyChrome.cream.withValues(alpha: 0.82),
          ),
        ),
      ],
    );
  }
}
