/// OR flagship copy column — scale-safe Turkish body.
library;

import 'package:flutter/material.dart';

import '../../../core/accessibility/oracly_a11y.dart';
import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/reading_typography.dart';

class HomeReferenceOrFlagshipCopy extends StatelessWidget {
  const HomeReferenceOrFlagshipCopy({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final scale =
            MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.4);
        final titleSize = (20 / scale).clamp(16.0, 20.0);
        final bodySize = (12.5 / scale).clamp(11.0, 12.5);
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: box.maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ReadingTypography.title(
                    color: OraclyChrome.cream.withValues(alpha: 0.98),
                  ).copyWith(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ReadingTypography.secondary(
                    color: OraclyA11y.creamSecondary(OraclyChrome.cream),
                  ).copyWith(fontSize: bodySize, height: 1.32),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
