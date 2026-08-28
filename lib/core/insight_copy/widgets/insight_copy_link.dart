/// Quiet text action — copy this insight.
library;

import 'package:flutter/material.dart';

import '../../design_system/oracly_chrome.dart';
import '../../theme/reading_typography.dart';
import '../../../shared/widgets/oracly_pressable.dart';
import '../insight_copy_action.dart';
import '../insight_copy_strings.dart';
import '../insight_copy_text.dart';

class InsightCopyLink extends StatelessWidget {
  const InsightCopyLink({
    super.key,
    required this.text,
    this.align = Alignment.center,
  });

  final String text;
  final Alignment align;

  @override
  Widget build(BuildContext context) {
    if (InsightCopyText.clean(text).isEmpty) {
      return const SizedBox.shrink();
    }
    final label = InsightCopyStrings.action;
    return Align(
      alignment: align,
      child: Semantics(
        button: true,
        label: label,
        child: OraclyPressable(
          onTap: () => InsightCopyAction.copy(context, text),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text(
                label,
                style: ReadingTypography.footnote(
                  color: OraclyChrome.goldLight.withValues(alpha: 0.82),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
