/// Yıldızname hub — archive wheel, chapters, doors, next quiet step.
library;

import 'package:flutter/material.dart';

import '../../../../features/birth_chart/models/birth_profile.dart';
import '../../models/star_map_reading.dart';
import 'star_map_reference_chart.dart';
import 'star_map_reference_hub_menus.dart';
import 'star_map_reference_menu_cards.dart';
import 'star_map_reference_status.dart';
import 'star_map_reference_themes.dart';
import 'star_map_reference_tokens.dart';
import 'star_map_result_section.dart';

class StarMapReferenceHubBody extends StatelessWidget {
  const StarMapReferenceHubBody({
    super.key,
    required this.chart,
    required this.hasBirth,
    this.birthPending = false,
    required this.onBirth,
    required this.onOpenLeaf,
    required this.reading,
    required this.onRefresh,
    this.profile,
    this.cityName,
    this.portrait,
    this.portraitHeading,
  });

  final double chart;
  final bool hasBirth;
  final bool birthPending;
  final VoidCallback onBirth;
  final VoidCallback onOpenLeaf;
  final StarMapReading reading;
  final VoidCallback onRefresh;
  final BirthProfile? profile;
  final String? cityName;

  /// Chart-grounded chapters; null keeps the archive copy.
  final List<StarMapResultSection>? portrait;
  final String? portraitHeading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StarMapReferenceChart(diameter: chart),
        SizedBox(height: StarMapReferenceTokens.chartToStatus),
        StarMapReferenceThemes(
          reading: reading,
          sections: portrait,
          heading: portraitHeading,
        ),
        SizedBox(height: StarMapReferenceTokens.statusToMenus),
        StarMapReferenceMenuCards(
          items: StarMapReferenceHubMenus.build(
            context: context,
            reading: reading,
            profile: profile,
            onRefresh: onRefresh,
            onPrimary: hasBirth ? onOpenLeaf : onBirth,
          ),
        ),
        SizedBox(height: StarMapReferenceTokens.statusToMenus),
        StarMapReferenceStatus(
          hasBirthInfo: hasBirth,
          birthPending: birthPending,
          cityName: cityName,
          onPrimary: hasBirth ? onOpenLeaf : onBirth,
        ),
      ],
    );
  }
}
