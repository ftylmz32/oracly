from pathlib import Path

def w(path, body):
    Path(path).write_text(body, encoding="utf-8", newline="\n")
    print(path, len(body.splitlines()))

w("lib/features/tarot/presentation/epic031/tarot_epic031_title_block.dart", """/// Invitation under TAROT — chamber mood, no certainty.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/craftsmanship_rhythm.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/tarot_polish_copy.dart';

class TarotEpic031TitleBlock extends StatelessWidget {
  const TarotEpic031TitleBlock({super.key});

  static String instruction = TarotPolishCopy.startInstruction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, AppSpacing.sm, 16, 0),
      child: Column(
        children: [
          Text(
            instruction,
            textAlign: TextAlign.center,
            style: ReadingTypography.opening(
              color: AppColors.cream.withValues(alpha: 0.92),
            ).copyWith(
              fontSize: 18,
              height: 1.35,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.gold.withValues(alpha: 0.34),
                  Colors.transparent,
                ],
              ),
            ),
            child: const SizedBox(width: 56, height: 1),
          ),
          const SizedBox(height: 8),
          Text(
            TarotPolishCopy.entryQuestionHint,
            textAlign: TextAlign.center,
            style: ReadingTypography.footnote(
              color: AppColors.textSecondary.withValues(alpha: 0.72),
            ).copyWith(
              letterSpacing: CraftsmanshipRhythm.sectionLabelTracking * 0.35,
            ),
          ),
        ],
      ),
    );
  }
}
""")

w("lib/features/tarot/presentation/widgets/tarot_entry/tarot_entry_spread_tile.dart", """/// Ritual spread choice — premium chamber tile, not a list row.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/reading_typography.dart';
import '../../../../../shared/widgets/oracly_pressable.dart';
import 'tarot_entry_spread_choice.dart';

class TarotEntrySpreadTile extends StatelessWidget {
  const TarotEntrySpreadTile({
    super.key,
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final TarotEntrySpreadChoice choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gold = AppColors.goldLight;
    final count = choice.type.cardCount;
    return Semantics(
      button: true,
      selected: selected,
      label: '${choice.title}. ${choice.blurb}',
      child: OraclyPressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm + 2,
            AppSpacing.md,
            AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: gold.withValues(alpha: selected ? 0.48 : 0.14),
              width: selected ? 1.15 : 0.9,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: selected ? 0.07 : 0.03),
                AppColors.royalViolet.withValues(alpha: selected ? 0.18 : 0.08),
                const Color(0xFF070510).withValues(alpha: 0.55),
              ],
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.10),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              _CountMark(count: count, selected: selected),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      choice.title,
                      style: ReadingTypography.sectionLabel(
                        color: gold.withValues(alpha: selected ? 0.96 : 0.74),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      choice.blurb,
                      style: ReadingTypography.bodySmall(
                        color: AppColors.textSecondary.withValues(
                          alpha: selected ? 0.94 : 0.78,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountMark extends StatelessWidget {
  const _CountMark({required this.count, required this.selected});

  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: selected ? 0.42 : 0.18),
        ),
        color: const Color(0xFF0A0614).withValues(alpha: 0.85),
      ),
      child: Text(
        '$count',
        style: ReadingTypography.sectionLabel(
          color: AppColors.goldLight.withValues(alpha: selected ? 0.95 : 0.7),
          fontSize: 13,
        ),
      ),
    );
  }
}
""")

w("lib/features/tarot/art/tarot_card_back_stars.dart", """/// Sparse cosmic dust for the Oracly deck back — never UI chrome.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class TarotCardBackStars extends StatelessWidget {
  const TarotCardBackStars({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: CustomPaint(painter: _StarsPainter(), child: SizedBox.expand()),
    );
  }
}

class _StarsPainter extends CustomPainter {
  const _StarsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.gold.withValues(alpha: 0.22);
    for (var i = 0; i < 14; i++) {
      final a = i * 2.399963;
      final r = size.shortestSide * (0.18 + (i % 5) * 0.07);
      final c = Offset(size.width * 0.5, size.height * 0.5);
      final p = c + Offset(math.cos(a) * 0.95, math.sin(a) * 1.15) * r;
      canvas.drawCircle(p, 0.55 + (i % 3) * 0.2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
""")

# Patch card back to include stars
back = Path("lib/features/tarot/art/tarot_card_back_art.dart").read_text(encoding="utf-8")
if "TarotCardBackStars" not in back:
    back = back.replace(
        "import 'tarot_card_asset.dart';\n",
        "import 'tarot_card_asset.dart';\nimport 'tarot_card_back_stars.dart';\n",
    )
    back = back.replace(
        """        const ColoredBox(color: Color(0xFF070510)),
        OraclyAssetImage(
""",
        """        const ColoredBox(color: Color(0xFF070510)),
        const TarotCardBackStars(),
        OraclyAssetImage(
""",
    )
    # Soften brand mark slightly so stars + geometry read
    back = back.replace("widthFactor: 0.42", "widthFactor: 0.38")
    Path("lib/features/tarot/art/tarot_card_back_art.dart").write_text(
        back, encoding="utf-8", newline="\n"
    )
    print("card back patched", len(back.splitlines()))

# polish copy getter
pc = Path("lib/features/tarot/copy/tarot_polish_copy.dart").read_text(encoding="utf-8")
if "revealComplete" not in pc:
    pc = pc.replace(
        "  static String get cutDeck => _t('tarot.cut_deck');\n",
        "  static String get cutDeck => _t('tarot.cut_deck');\n"
        "  static String get revealComplete => _t('tarot.reveal.complete');\n",
    )
    Path("lib/features/tarot/copy/tarot_polish_copy.dart").write_text(
        pc, encoding="utf-8", newline="\n"
    )
    print("polish copy ok")
