/// Optional soft Premium journey invite — only when real depth exists.
library;

import 'package:flutter/material.dart';

import '../../../core/accessibility/oracly_a11y.dart';
import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../shared/widgets/oracly_pressable.dart';

class HomeOracleNextActionPremiumNote extends StatelessWidget {
  const HomeOracleNextActionPremiumNote({
    super.key,
    required this.hint,
    required this.cta,
    required this.onPremium,
    this.compact = false,
  });

  final String hint;
  final String cta;
  final VoidCallback onPremium;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: compact ? 8 : 10),
        Text(
          hint,
          maxLines: compact ? 2 : 3,
          overflow: TextOverflow.ellipsis,
          style: ReadingTypography.footnote(
            color: OraclyChrome.cream.withValues(alpha: 0.68),
          ).copyWith(height: 1.35),
        ),
        if (cta.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: OraclyPressable(
              onTap: onPremium,
              child: Text(
                cta,
                style: ReadingTypography.footnote(
                  color: OraclyA11y.goldReadable(OraclyChrome.goldLight),
                ).copyWith(fontSize: 12, letterSpacing: 0.3),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
