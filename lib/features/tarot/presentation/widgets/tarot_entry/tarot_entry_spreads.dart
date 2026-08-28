/// Spread list for the tarot entry chamber.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/models/tarot_spread.dart';
import 'tarot_entry_spread_choice.dart';
import 'tarot_entry_spread_tile.dart';

class TarotEntrySpreads extends StatelessWidget {
  const TarotEntrySpreads({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final TarotSpreadType selected;
  final ValueChanged<TarotSpreadType> onSelected;

  @override
  Widget build(BuildContext context) {
    final choices = TarotEntrySpreadChoice.offered();
    return Column(
      children: [
        for (var i = 0; i < choices.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          TarotEntrySpreadTile(
            choice: choices[i],
            selected: choices[i].type == selected,
            onTap: () => onSelected(choices[i].type),
          ),
        ],
      ],
    );
  }
}
