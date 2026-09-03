/// Settled placement slots for multi-card spreads.
library;

import "package:flutter/material.dart";

import "../../../../core/l10n/l10n.dart";
import "../../../../core/theme/app_colors.dart";
import "../../../../core/theme/app_text_styles.dart";
import "../../presentation/widgets/card_reveal/card_reveal_spread.dart";
import "ritual_card_shell.dart";

class RitualSpreadSlots extends StatelessWidget {
  const RitualSpreadSlots({
    super.key,
    required this.placed,
    required this.totalSlots,
  });

  final List<RevealCardData> placed;
  final int totalSlots;

  static List<String> get labels3 => [
        OraclyL10n.t('tarot.pos.past.slot'),
        OraclyL10n.t('tarot.pos.present.slot'),
        OraclyL10n.t('tarot.pos.future.slot'),
      ];

  @override
  Widget build(BuildContext context) {
    if (totalSlots <= 1) return const SizedBox.shrink();
    final labels = totalSlots == 3
        ? labels3
        : List.generate(totalSlots, (i) => "${i + 1}");
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < totalSlots; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          _Slot(
            label: labels[i.clamp(0, labels.length - 1)],
            card: i < placed.length ? placed[i] : null,
          ),
        ],
      ],
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({required this.label, this.card});

  final String label;
  final RevealCardData? card;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.gold.withValues(alpha: 0.72),
            letterSpacing: 1.6,
            fontSize: 9,
          ),
        ),
        const SizedBox(height: 6),
        if (card != null)
          RitualCardFace(
            label: card!.displayName,
            image: card!.imageAsset,
            reversed: card!.isReversed,
            width: 72,
            height: 120,
          )
        else
          Container(
            width: 72,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.22),
              ),
              color: const Color(0xFF0A0714).withValues(alpha: 0.55),
            ),
          ),
      ],
    );
  }
}
