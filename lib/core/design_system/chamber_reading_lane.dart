/// Supporting reading — gold rail, not another identical boxed card.
library;

import 'package:flutter/material.dart';

import '../reading_ux/reading_expand_section.dart';
import '../theme/app_spacing.dart';
import 'oracly_chrome.dart';
import 'oracly_soft_reveal.dart';

class ChamberReadingLane extends StatelessWidget {
  const ChamberReadingLane({
    super.key,
    required this.title,
    required this.body,
    this.index = 0,
    this.emphasis = false,
    this.maxLines,
  });

  final String title;
  final String body;
  final int index;
  final bool emphasis;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    if (body.trim().isEmpty) return const SizedBox.shrink();
    assert(maxLines == null || maxLines! > 0);
    return OraclySoftReveal(
      delay: Duration(milliseconds: 70 + index * 40),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: emphasis ? 2.2 : 1.15,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    OraclyChrome.goldLight.withValues(alpha: 0.92),
                    OraclyChrome.gold.withValues(alpha: 0.18),
                  ],
                ),
              ),
            ),
            SizedBox(width: AppSpacing.sm + 2),
            Expanded(
              child: ReadingExpandSection(title: title, body: body),
            ),
          ],
        ),
      ),
    );
  }
}
