/// One Destem grid cell — art, name, short meaning; never locked.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../deck/oracly_tarot_card.dart';
import 'destem_card_art.dart';
import 'destem_copy.dart';

class DestemCardTile extends StatelessWidget {
  const DestemCardTile({
    super.key,
    required this.card,
    required this.seen,
    required this.onTap,
  });

  final OraclyTarotCard card;
  final bool seen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final code = OraclyL10n.code;
    final name = card.name.of(code);
    final meaning = card.symbolicMeaning.of(code);
    return Semantics(
      button: true,
      label: '${DestemCopy.openHint}: $name',
      child: OraclyPressable(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: DestemCardArt(card: card)),
            SizedBox(height: AppSpacing.s8),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ReadingTypography.sectionLabel(
                color: OraclyChrome.cream.withValues(alpha: 0.92),
                fontSize: 11,
              ),
            ),
            SizedBox(height: AppSpacing.s4),
            Text(
              meaning,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: ReadingTypography.footnote(
                color: OraclyChrome.cream.withValues(alpha: 0.62),
              ),
            ),
            if (seen) ...[
              SizedBox(height: AppSpacing.s4),
              Text(
                DestemCopy.seen,
                textAlign: TextAlign.center,
                style: ReadingTypography.footnote(
                  color: OraclyChrome.goldLight.withValues(alpha: 0.72),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
