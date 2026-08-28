/// One report beat - engraved label, clear visual weight.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/chamber_ornament_heading.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/design_system/oracly_soft_reveal.dart';
import '../../../../core/theme/craftsmanship_rhythm.dart';
import '../../../../core/theme/reading_typography.dart';
import 'astrology_content_separator.dart';
import 'astrology_reference_card_shell.dart';
import 'astrology_reference_tokens.dart';

enum AstrologyResultBeatKind { theme, message, attention, action }

class AstrologyResultBeat extends StatelessWidget {
  const AstrologyResultBeat({
    super.key,
    required this.label,
    required this.kind,
    required this.child,
    this.index = 0,
  });

  final String label;
  final AstrologyResultBeatKind kind;
  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    return OraclySoftReveal(
      delay: Duration(milliseconds: 60 + index * 50),
      child: Padding(
        padding: EdgeInsets.only(bottom: CraftsmanshipRhythm.betweenSections),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ChamberOrnamentHeading(label: label),
            SizedBox(height: CraftsmanshipRhythm.afterTitle * 0.5),
            if (kind == AstrologyResultBeatKind.theme ||
                kind == AstrologyResultBeatKind.message)
              child
            else
              AstrologyReferenceCardShell(
                borderRadius: AstrologyReferenceTokens.dailyCardRadius,
                padding: EdgeInsets.zero,
                premium: true,
                glowStrength:
                    kind == AstrologyResultBeatKind.action ? 1.08 : 0.98,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: kind == AstrologyResultBeatKind.action
                            ? 2.6
                            : 1.8,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(20),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              OraclyChrome.goldLight.withValues(alpha: 0.92),
                              OraclyChrome.gold.withValues(alpha: 0.35),
                              OraclyChrome.gold.withValues(alpha: 0.06),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: AstrologyReferenceTokens.dailyCardPadding,
                          child: child,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AstrologyResultThemeLine extends StatelessWidget {
  const AstrologyResultThemeLine({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final value = text.trim();
    if (value.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: ReadingTypography.display(
            color: OraclyChrome.goldLight.withValues(alpha: 0.94),
          ).copyWith(fontSize: 22, letterSpacing: 0.4),
        ),
        const AstrologyContentSeparator(vertical: 6),
      ],
    );
  }
}
