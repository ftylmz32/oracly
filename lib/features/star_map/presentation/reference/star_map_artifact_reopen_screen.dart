/// Exact Yıldızname artifact reopen — stored chrome only, no birth data.
library;

import 'package:flutter/material.dart';

import '../../artifacts/yildizname_artifact.dart';
import '../../artifacts/yildizname_artifact_or_context.dart';
import '../../artifacts/yildizname_artifact_presentation.dart';
import '../../models/star_map_reading.dart';
import 'star_map_reference_result_screen.dart';

class StarMapArtifactReopenScreen extends StatelessWidget {
  const StarMapArtifactReopenScreen({super.key, required this.artifact});

  final YildiznameArtifact artifact;

  @override
  Widget build(BuildContext context) {
    final presentation = YildiznameArtifactPresentation.of(artifact);
    final planets = presentation.planets.whereType<StarMapPlanetInfluence>().toList();
    return StarMapReferenceResultScreen(
      title: presentation.title.trim().isEmpty
          ? 'Yıldızname'
          : presentation.title,
      sections: presentation.sections,
      planets: planets,
      artifactId: artifact.id,
      artifactCreatedAt: artifact.createdAtUtc,
      // Prose-only OR context — never birth date/place/time.
      readingContext: YildiznameArtifactOrContext.build(artifact),
    );
  }
}
