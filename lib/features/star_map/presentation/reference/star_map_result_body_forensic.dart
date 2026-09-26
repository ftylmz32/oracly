/// Phase 7C forensic freeze body — linear sections, pre-7D chrome.
library;

import 'package:flutter/material.dart';

import '../../../../features/ai/oracle_conversation/models/oracle_reading_context.dart';
import '../../result/yildizname_result_presentation.dart';
import '../../result/yildizname_result_types.dart';
import 'star_map_fact_snapshot_plate.dart';
import 'star_map_reference_planet_card.dart';
import 'star_map_result_footer.dart';
import 'star_map_result_section_card.dart';
import 'star_map_scope_note.dart';

abstract final class StarMapResultBodyForensic {
  StarMapResultBodyForensic._();

  static List<Widget> build({
    required YildiznameResultPresentation presentation,
    required OracleReadingContext? readingContext,
    required String insight,
  }) {
    final sections = presentation.sections;
    final hasSummary =
        sections.any((s) => s.role == YildiznameSectionRole.summary);
    final out = <Widget>[];
    final disclosure = presentation.scopeDisclosure;
    if (disclosure != null) out.add(StarMapScopeNote(disclosure: disclosure));
    if (presentation.factSnapshot.isNotEmpty) {
      out.add(StarMapFactSnapshotPlate(snapshot: presentation.factSnapshot));
    }
    for (var i = 0; i < sections.length; i++) {
      out.add(
        StarMapResultSectionCard(
          section: sections[i],
          index: i,
          showSeparator: i > 0,
          legacyHero: !hasSummary && i == 0,
          forensicFlat: true,
        ),
      );
    }
    for (final planet in presentation.planets) {
      out.add(StarMapReferencePlanetCard(planet: planet));
    }
    out.add(
      StarMapResultFooter(
        title: presentation.title,
        sections: sections,
        planets: presentation.planets,
        insight: insight,
        artifactId: presentation.artifactId,
        artifactCreatedAt: presentation.createdAtUtc,
        readingContext: readingContext,
      ),
    );
    return out;
  }
}
