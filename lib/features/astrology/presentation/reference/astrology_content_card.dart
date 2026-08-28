/// Interpretation card — hierarchy, gold accents, readable body.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/design_system/oracly_soft_reveal.dart';
import '../../../../core/theme/craftsmanship_rhythm.dart';
import '../../../../core/theme/reading_typography.dart';
import 'astrology_content_lane_meta.dart';
import 'astrology_content_separator.dart';
import 'astrology_reference_card_shell.dart';
import 'astrology_reference_tokens.dart';

class AstrologyContentCard extends StatelessWidget {
  const AstrologyContentCard({
    super.key,
    required this.kind,
    required this.body,
    this.index = 0,
    this.compact = false,
  });

  final AstrologyContentLaneKind kind;
  final String body;
  final int index;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = body.trim();
    if (text.isEmpty) return const SizedBox.shrink();
    final pad = compact
        ? AstrologyReferenceTokens.dailyCardPaddingCompact
        : AstrologyReferenceTokens.dailyCardPadding;

    return OraclySoftReveal(
      delay: Duration(milliseconds: 70 + index * 45),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: compact
              ? CraftsmanshipRhythm.afterTitle
              : CraftsmanshipRhythm.betweenSections,
        ),
        child: AstrologyReferenceCardShell(
          borderRadius: AstrologyReferenceTokens.dailyCardRadius,
          padding: EdgeInsets.zero,
          premium: true,
          glowStrength: compact ? 0.96 : 1.06,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _GoldRail(emphasis: !compact),
                Expanded(
                  child: Padding(
                    padding: pad,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AstrologyContentHeader(
                          kind: kind,
                          compact: compact,
                        ),
                        AstrologyContentSeparator(
                          vertical: compact ? 6 : 8,
                        ),
                        Text(
                          text,
                          textAlign: TextAlign.start,
                          style: (compact
                                  ? ReadingTypography.bodySmall
                                  : ReadingTypography.body)(
                            color: OraclyChrome.cream.withValues(
                              alpha: CraftsmanshipRhythm.bodyInk,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoldRail extends StatelessWidget {
  const _GoldRail({required this.emphasis});

  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: emphasis ? 2.4 : 1.6,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            OraclyChrome.goldLight.withValues(alpha: 0.92),
            OraclyChrome.gold.withValues(alpha: 0.42),
            OraclyChrome.gold.withValues(alpha: 0.08),
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
    );
  }
}
