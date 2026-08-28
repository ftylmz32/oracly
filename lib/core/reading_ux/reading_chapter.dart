/// Core reading block — full text, paragraph rhythm, never clipped.
library;

import 'package:flutter/material.dart';

import '../design_system/oracly_chrome.dart';
import '../theme/craftsmanship_rhythm.dart';
import '../theme/reading_flow_text.dart';
import '../theme/reading_typography.dart';

class ReadingChapter extends StatelessWidget {
  const ReadingChapter({
    super.key,
    required this.body,
    this.hero = false,
    this.align = TextAlign.start,
  });

  final String body;
  final bool hero;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    final text = body.trim();
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: CraftsmanshipRhythm.betweenSections),
      child: ReadingFlowText(
        text: text,
        textAlign: align,
        emphasizeFirst: hero,
        style: hero
            ? ReadingTypography.bodyCore(
                color: OraclyChrome.cream.withValues(alpha: 0.94),
              )
            : ReadingTypography.body(
                color: OraclyChrome.cream.withValues(alpha: 0.90),
              ),
      ),
    );
  }
}
