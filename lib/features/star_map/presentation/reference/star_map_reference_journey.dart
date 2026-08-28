/// Personal archive chapter — real discovery themes only.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/chamber_symbol_pills.dart';
import '../../copy/star_map_polish_copy.dart';
import '../../models/star_map_reading.dart';
import 'star_map_hub_insight_card.dart';
import 'star_map_reading_presentation.dart';

class StarMapReferenceJourney extends StatelessWidget {
  const StarMapReferenceJourney({
    super.key,
    required this.reading,
    this.themeLabels = const [],
  });

  final StarMapReading reading;
  final List<String> themeLabels;

  @override
  Widget build(BuildContext context) {
    final clean = themeLabels.where((e) => e.trim().isNotEmpty).toList();
    return StarMapHubInsightCard(
      icon: Icons.auto_stories_outlined,
      title: StarMapPolishCopy.journeyTitle,
      body: StarMapReadingPresentation.journeyBody(reading),
      glowStrength: 1.22,
      delay: const Duration(milliseconds: 120),
      footer: clean.isEmpty
          ? null
          : ChamberSymbolPills(title: '', labels: clean, index: 4),
    );
  }
}
