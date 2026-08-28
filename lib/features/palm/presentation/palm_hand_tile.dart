/// One left/right palm tile — selected gold, quiet midnight otherwise.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../shared/widgets/oracly_pressable.dart';
import '../models/palm_hand.dart';
import 'palm_hand_glyph.dart';
import 'palm_tokens.dart';

class PalmHandTile extends StatelessWidget {
  const PalmHandTile({
    super.key,
    required this.hand,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final PalmHand hand;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: OraclyPressable(
        onTap: onTap,
        borderRadius: PalmTokens.cardRadius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: PalmTokens.cardRadius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: selected
                    ? [
                        OraclyChrome.gold.withValues(alpha: 0.22),
                        OraclyChrome.midnight.withValues(alpha: 0.72),
                      ]
                    : [
                        OraclyChrome.midnight.withValues(alpha: 0.55),
                        OraclyChrome.midnight.withValues(alpha: 0.38),
                      ],
              ),
              border: Border.all(
                color: OraclyChrome.gold.withValues(
                  alpha: selected ? 0.72 : 0.22,
                ),
                width: selected ? 1.15 : 0.9,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: OraclyChrome.gold.withValues(alpha: 0.22),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: PalmTokens.amberGlow.withValues(alpha: 0.10),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PalmHandGlyph(
                    left: hand == PalmHand.left,
                    selected: selected,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ReadingTypography.sectionLabel(fontSize: 11).copyWith(
                      letterSpacing: selected ? 1.8 : 1.4,
                      color: PalmTokens.cream.withValues(
                        alpha: selected ? 0.96 : 0.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
