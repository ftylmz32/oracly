/// Continuous reading chapter — typography and space, never a gold card.
library;

import 'package:flutter/material.dart';

import '../reading_ux/reading_chapter.dart';
import '../reading_ux/reading_expand_section.dart';
import 'oracly_soft_reveal.dart';

class ChamberNarrativeBlock extends StatelessWidget {
  const ChamberNarrativeBlock({
    super.key,
    required this.body,
    this.kicker,
    this.hero = false,
    this.onTap,
    this.delay = Duration.zero,
    this.maxLines,
    this.align = TextAlign.start,
  });

  final String body;
  final String? kicker;
  final bool hero;
  final VoidCallback? onTap;
  final Duration delay;

  /// Kept for call-site compatibility. Long-form reading never truncates.
  final int? maxLines;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    assert(maxLines == null || maxLines! > 0);
    if (body.trim().isEmpty) return const SizedBox.shrink();
    final hasKicker = (kicker ?? '').trim().isNotEmpty;
    final Widget text;
    if (hasKicker) {
      text = ReadingExpandSection(title: kicker, body: body, hero: hero);
    } else if (hero) {
      text = ReadingChapter(body: body, hero: true, align: align);
    } else {
      text = ReadingExpandSection(body: body);
    }
    return OraclySoftReveal(
      delay: delay,
      child: onTap == null ? text : GestureDetector(onTap: onTap, child: text),
    );
  }
}
