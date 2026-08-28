/// Sign as a doorway into today's sky — scale over chrome.
library;

import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../content/astrology/models/astrology_content.dart';
import 'astrology_reference_sign_art.dart';
import 'astrology_reference_tokens.dart';

class AstrologyReferenceSignCard extends StatelessWidget {
  const AstrologyReferenceSignCard({
    super.key,
    required this.sign,
    this.height,
  });

  final ZodiacSignContent sign;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final h = height ?? AstrologyReferenceTokens.signCardHeight;
    return SizedBox(
      height: h,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned.fill(
            child: AstrologyReferenceSignArt(signId: sign.id, size: h),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.s8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  OraclyL10n.t('zodiac.${sign.id}'),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ReadingTypography.cardTitle(
                    color: OraclyChrome.cream.withValues(alpha: 0.96),
                  ).copyWith(fontSize: 28, letterSpacing: 0.6),
                ),
                SizedBox(height: AppSpacing.s4),
                Text(
                  OraclyL10n.t('zodiac.range.${sign.id}'),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ReadingTypography.footnote(
                    color: OraclyChrome.cream.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
