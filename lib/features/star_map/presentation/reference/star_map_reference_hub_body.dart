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

class StarMapReferenceHubBody extends StatelessWidget {
  const StarMapReferenceHubBody({
    super.key,
    required this.chart,
    required this.hasBirth,
    required this.onBirth,
    required this.onOpenLeaf,
    required this.reading,
    required this.onRefresh,
    this.profile,
    this.cityName,
  });

  final double chart;
  final bool hasBirth;
  final VoidCallback onBirth;
  final VoidCallback onOpenLeaf;
  final StarMapReading reading;
  final VoidCallback onRefresh;
  final BirthProfile? profile;
  final String? cityName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StarMapReferenceChart(diameter: chart),
        SizedBox(height: StarMapReferenceTokens.chartToStatus),
        StarMapReferenceThemes(reading: reading),
        SizedBox(height: StarMapReferenceTokens.statusToMenus),
        StarMapReferenceMenuCards(
          items: StarMapReferenceHubMenus.build(
            context: context,
            reading: reading,
            profile: profile,
            onRefresh: onRefresh,
          ),
        ),
        SizedBox(height: StarMapReferenceTokens.statusToMenus),
        StarMapReferenceStatus(
          hasBirthInfo: hasBirth,
          cityName: cityName,
          onPrimary: hasBirth ? onOpenLeaf : onBirth,
        ),
      ],
    );
  }
}
