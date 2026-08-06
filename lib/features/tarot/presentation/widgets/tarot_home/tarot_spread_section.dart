/// OR-401 / OR-410 — Spread selection crystal section.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/providers/app_providers.dart';
import 'tarot_home_crystal_panel.dart';
import 'tarot_home_data.dart';
import 'tarot_home_ornaments.dart';
import 'oracly_sacred_identity.dart';
import 'tarot_spread_card.dart';

/// Luxury crystal panel with 2×2 sacred ritual grid.
class TarotSpreadSection extends ConsumerWidget {
  const TarotSpreadSection({
    super.key,
    this.onSpreadSelected,
  });

  static const String _title = 'Fal Türünü Seç';

  final ValueChanged<TarotSpreadOption>? onSpreadSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTitle = ref.watch(selectedSpreadProvider);

    return TarotHomeCrystalPanel(
      lightTier: OraclyLightTier.upperChamber,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TarotHomeSectionHeading(title: _title),
          SizedBox(height: OraclyRhythm.sectionTitleGap),
          for (var row = 0; row < 2; row++) ...[
            if (row > 0) SizedBox(height: OraclyRhythm.spreadGridGap),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var col = 0; col < 2; col++) ...[
                  if (col > 0) SizedBox(width: OraclyRhythm.spreadColumnGap),
                  Expanded(
                    child: TarotSpreadCard(
                      option: TarotHomeSpreads.options[row * 2 + col],
                      gridIndex: row * 2 + col,
                      selected: TarotHomeSpreads.options[row * 2 + col].title ==
                          selectedTitle,
                      onTap: () => onSpreadSelected?.call(
                        TarotHomeSpreads.options[row * 2 + col],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
