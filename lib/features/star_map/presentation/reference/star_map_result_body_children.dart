/// Canonical visual order for typed Yıldızname result body children.
library;

import 'package:flutter/material.dart';

import '../../result/yildizname_result_presentation.dart';
import '../../result/yildizname_result_types.dart';
import 'star_map_continuity_echo.dart';
import 'star_map_fact_snapshot_plate.dart';
import 'star_map_historical_status.dart';
import 'star_map_reference_planet_card.dart';
import 'star_map_result_body_forensic.dart';
import 'star_map_result_footer.dart';
import 'star_map_result_section.dart';
import 'star_map_result_section_card.dart';
import 'star_map_scope_note.dart';

abstract final class StarMapResultBodyChildren {
  StarMapResultBodyChildren._();

  static List<Widget> build({
    required YildiznameResultPresentation presentation,
  }) {
    if (presentation.forensicFlatSections) {
      return StarMapResultBodyForensic.build(presentation: presentation);
    }
    final sections = presentation.sections;
    final summaries = _role(sections, YildiznameSectionRole.summary);
    final chapters = _role(sections, YildiznameSectionRole.chapter);
    final reflections = _role(sections, YildiznameSectionRole.reflection);
    final closings = _role(sections, YildiznameSectionRole.closing);
    final hasSummary = summaries.isNotEmpty;
    var chapterIndex = 0;
    var shown = false;
    final out = <Widget>[];

    void addCard(StarMapResultSection s, {bool legacyHero = false}) {
      out.add(
        StarMapResultSectionCard(
          section: s,
          index: chapterIndex,
          showSeparator: shown,
          legacyHero: legacyHero,
        ),
      );
      if (s.role == YildiznameSectionRole.chapter) chapterIndex++;
      shown = true;
    }

    final historical = presentation.historicalStatus;
    if (historical != null) {
      out.add(StarMapHistoricalStatus(status: historical));
    }
    final disclosure = presentation.scopeDisclosure;
    if (disclosure != null) out.add(StarMapScopeNote(disclosure: disclosure));
    if (presentation.factSnapshot.isNotEmpty) {
      out.add(StarMapFactSnapshotPlate(snapshot: presentation.factSnapshot));
    }
    for (final s in summaries) {
      addCard(s);
    }
    for (var i = 0; i < chapters.length; i++) {
      addCard(chapters[i], legacyHero: !hasSummary && i == 0);
    }
    if (presentation.continuity.isNotEmpty) {
      out.add(
        StarMapContinuityEcho(
          continuity: presentation.continuity,
          showSeparator: shown,
        ),
      );
      shown = true;
    }
    for (final s in reflections) {
      addCard(s);
    }
    for (final s in closings) {
      addCard(s);
    }
    for (final planet in presentation.planets) {
      out.add(StarMapReferencePlanetCard(planet: planet));
    }
    out.add(StarMapResultFooter(
      actions: presentation.actions,
      forensicLegacyActionOrder: presentation.forensicLegacyActionOrder,
    ));
    return out;
  }

  static List<StarMapResultSection> _role(
    List<StarMapResultSection> sections,
    YildiznameSectionRole role,
  ) =>
      [for (final s in sections) if (s.role == role) s];
}
