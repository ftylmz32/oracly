/// Sign identity under the instrument — never painted onto the celestial art.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../content/astrology/models/astrology_content.dart';

class AstrologyHubCaption extends StatelessWidget {
  const AstrologyHubCaption({super.key, required this.sign});

  final ZodiacSignContent sign;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          OraclyL10n.t('zodiac.${sign.id}').toUpperCase(),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ReadingTypography.display(
            color: OraclyChrome.cream.withValues(alpha: 0.96),
          ).copyWith(fontSize: 17),
        ),
        const SizedBox(height: 4),
        Text(
          OraclyL10n.t('zodiac.range.${sign.id}'),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ReadingTypography.micro(
            color: OraclyChrome.cream.withValues(alpha: 0.68),
          ),
        ),
      ],
    );
  }
}
