/// Observed marks — numbered when grounded to the cup photo.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/craftsmanship_rhythm.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/coffee_copy.dart';
import '../../models/coffee_symbol.dart';
import 'coffee_observation_card.dart';
import 'coffee_result_markers.dart';
import 'coffee_result_separator.dart';

class CoffeeResultObservations extends StatelessWidget {
  const CoffeeResultObservations({
    super.key,
    required this.symbols,
    this.markKeys = const {},
  });

  final List<CoffeeSymbol> symbols;
  final Map<int, GlobalKey> markKeys;

  @override
  Widget build(BuildContext context) {
    final marks = CoffeeGroundedMarks.from(symbols);
    final grounded = {
      for (final mark in marks) mark.label.toLowerCase(): mark.index,
    };
    final rows = <CoffeeObservationRow>[];
    for (final symbol in symbols) {
      if (!symbol.trust.isFirm || symbol.name.trim().isEmpty) continue;
      final name = symbol.name.trim();
      rows.add(
        CoffeeObservationRow(
          index: grounded[name.toLowerCase()],
          name: name,
          reading: _reading(symbol),
        ),
      );
      if (rows.length >= 5) break;
    }
    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CoffeeResultSeparator(),
        Text(
          CoffeeCopy.visualTitle,
          style: ReadingTypography.sectionLabel(
            color: OraclyChrome.goldLight.withValues(alpha: 0.86),
          ),
        ),
        SizedBox(height: CraftsmanshipRhythm.afterTitle),
        for (final row in rows) ...[
          KeyedSubtree(
            key: row.index == null
                ? ValueKey('obs-${row.name}')
                : (markKeys[row.index!] ?? ValueKey('obs-${row.index}')),
            child: CoffeeObservationCard(row: row),
          ),
          SizedBox(height: CraftsmanshipRhythm.paragraphGap),
        ],
      ],
    );
  }

  String _reading(CoffeeSymbol symbol) {
    final line = symbol.interpretation.trim().isNotEmpty
        ? symbol.interpretation.trim()
        : symbol.meaning.trim();
    if (line.isEmpty) return '';
    return line.length > 160 ? '${line.substring(0, 157)}…' : line;
  }
}
