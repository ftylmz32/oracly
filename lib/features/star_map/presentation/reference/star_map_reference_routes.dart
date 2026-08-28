/// Navigation from the Yıldızname hub into real results.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';

import '../../../../features/ai/oracle_conversation/models/oracle_reading_context_sources.dart';
import '../../../../features/birth_chart/models/birth_profile.dart';
import '../../../../features/birth_chart/presentation/screens/birth_chart_screen.dart';
import '../../copy/star_map_polish_copy.dart';
import '../../models/star_map_reading.dart';
import '../../services/star_map_personalization.dart';
import 'star_map_reference_result_screen.dart';

abstract final class StarMapReferenceRoutes {
  StarMapReferenceRoutes._();

  static bool _navigating = false;

  static Future<void> openBirthChart(
    BuildContext context, {
    VoidCallback? onReturn,
  }) async {
    if (_navigating) return;
    _navigating = true;
    try {
      ProviderScope.containerOf(context, listen: false)
          .read(analyticsServiceProvider)
          .logStarMapCompleted();
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const BirthChartScreen(),
        ),
      );
      onReturn?.call();
    } finally {
      _navigating = false;
    }
  }

  static void openSkyMessage(
    BuildContext context,
    StarMapReading reading, {
    BirthProfile? profile,
  }) {
    final sky = reading.skyMessage;
    _openResult(
      context,
      title: StarMapPolishCopy.skyMessageTitle,
      sections: [
        StarMapResultSection(
          title: StarMapPolishCopy.skyHeadline,
          body: sky.today,
        ),
        StarMapResultSection(
          title: StarMapPolishCopy.skyMeaning,
          body: sky.interpretation,
        ),
        StarMapResultSection(
          title: StarMapPolishCopy.skyAdvice,
          body: sky.advice,
        ),
      ],
      reading: reading,
      profile: profile,
      sectionLabel: StarMapPolishCopy.skyMessageTitle,
    );
  }

  static void openKarmic(
    BuildContext context,
    StarMapReading reading, {
    BirthProfile? profile,
  }) {
    _openResult(
      context,
      title: StarMapPolishCopy.karmicResultTitle,
      sections: StarMapPersonalization.innerThemeSections(reading),
      reading: reading,
      profile: profile,
      sectionLabel: StarMapPolishCopy.karmicTitle,
    );
  }

  static void openPlanets(
    BuildContext context,
    StarMapReading reading, {
    BirthProfile? profile,
  }) {
    _openResult(
      context,
      title: StarMapPolishCopy.planetsTitle,
      sections: [
        StarMapResultSection(
          title: StarMapPolishCopy.symbolicDisclaimer,
          body: StarMapPolishCopy.planetsCatalogueNote,
        ),
      ],
      planets: reading.planets,
      reading: reading,
      profile: profile,
      sectionLabel: StarMapPolishCopy.planetsTitle,
    );
  }

  static void _openResult(
    BuildContext context, {
    required String title,
    required List<StarMapResultSection> sections,
    required StarMapReading reading,
    required String sectionLabel,
    BirthProfile? profile,
    List<StarMapPlanetInfluence> planets = const [],
  }) {
    if (_navigating) return;
    _navigating = true;
    ProviderScope.containerOf(context, listen: false)
        .read(analyticsServiceProvider)
        .logStarMapCompleted();
    Navigator.of(context)
        .push(
      MaterialPageRoute<void>(
        builder: (_) => StarMapReferenceResultScreen(
          title: title,
          sections: sections,
          planets: planets,
          readingContext: OracleReadingContextSources.starMap(
            sectionLabel: sectionLabel,
            reading: reading,
            profile: profile,
            sectionLines: [
              for (final section in sections)
                if (section.body.trim().isNotEmpty)
                  '${section.title}: ${section.body}',
            ],
          ),
        ),
      ),
    )
        .whenComplete(() => _navigating = false);
  }
}
