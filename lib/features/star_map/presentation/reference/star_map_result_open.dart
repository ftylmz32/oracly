/// Pushes StarMap result after soft-fail legacy artifact capture.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../features/ai/oracle_conversation/models/oracle_reading_context_sources.dart';
import '../../../../features/birth_chart/models/birth_profile.dart';
import '../../artifacts/yildizname_legacy_section_kind.dart';
import '../../models/star_map_reading.dart';
import 'star_map_legacy_result_capture.dart';
import 'star_map_reference_result_screen.dart';

abstract final class StarMapResultOpen {
  StarMapResultOpen._();

  static Future<void> push(
    BuildContext context, {
    required String title,
    required List<StarMapResultSection> sections,
    required StarMapReading reading,
    required String sectionLabel,
    required YildiznameLegacySectionKind sectionKind,
    required void Function() onComplete,
    BirthProfile? profile,
    List<StarMapPlanetInfluence> planets = const [],
  }) async {
    ProviderScope.containerOf(context, listen: false)
        .read(analyticsServiceProvider)
        .logStarMapCompleted();
    final captured = await StarMapLegacyResultCapture.tryCapture(
      context,
      title: title,
      sections: sections,
      sectionKind: sectionKind,
      planets: planets,
    );
    if (!context.mounted) {
      onComplete();
      return;
    }
    await Navigator.of(context)
        .push(
      MaterialPageRoute<void>(
        builder: (_) => StarMapReferenceResultScreen(
          presentation: YildiznameResultPresentation.legacyLive(
            title: title,
            sections: sections,
            planets: planets,
            artifactId: captured.artifactId,
            createdAtUtc: captured.createdAt,
          ),
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
        .whenComplete(onComplete);
  }
}
