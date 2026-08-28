/// Thin contextual kicker — appears after the heading leaves the frame.
library;

import 'package:flutter/material.dart';

import '../design_system/oracly_chrome.dart';
import '../theme/reading_typography.dart';

class ReadingStickyKicker extends StatelessWidget {
  const ReadingStickyKicker({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final label = title.trim();
    if (label.isEmpty) return const SizedBox.shrink();
    return ColoredBox(
      color: OraclyChrome.midnight.withValues(alpha: 0.92),
      child: Align(
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            textAlign: TextAlign.center,
            style: ReadingTypography.sectionLabel(
              color: OraclyChrome.goldLight.withValues(alpha: 0.86),
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}
