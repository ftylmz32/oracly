/// Typed Yıldızname result presentation — the one contract the canonical
/// result screen renders.
library;

import 'package:flutter/foundation.dart';

import '../models/star_map_reading.dart';
import '../presentation/reference/star_map_result_section.dart';
import 'yildizname_continuity_presentation.dart';
import 'yildizname_fact_snapshot.dart';
import 'yildizname_result_presentation_build.dart';
import 'yildizname_result_types.dart';
import 'yildizname_scope_disclosure.dart';

export 'yildizname_scope_disclosure.dart';

part 'yildizname_result_presentation_eq.dart';

@immutable
final class YildiznameResultPresentation {
  const YildiznameResultPresentation({
    required this.source,
    required this.scope,
    required this.title,
    required this.sections,
    this.planets = const [],
    this.scopeDisclosure,
    this.artifactId,
    this.createdAtUtc,
    this.chromeLanguage,
    this.factSnapshot = YildiznameFactSnapshot.empty,
    this.continuity = YildiznameContinuityPresentation.empty,
    this.forensicFlatSections = false,
  });

  factory YildiznameResultPresentation.legacyLive({
    required String title,
    required List<StarMapResultSection> sections,
    List<StarMapPlanetInfluence> planets = const [],
    String? artifactId,
    DateTime? createdAtUtc,
    String? chromeLanguage,
  }) =>
      YildiznameResultPresentationBuild.legacyLive(
        title: title,
        sections: sections,
        planets: planets,
        artifactId: artifactId,
        createdAtUtc: createdAtUtc,
        chromeLanguage: chromeLanguage,
      );

  /// Test-only unscoped path for frozen Phase 7A baselines.
  factory YildiznameResultPresentation.unscoped({
    required String title,
    required List<StarMapResultSection> sections,
    List<StarMapPlanetInfluence> planets = const [],
    String? artifactId,
    DateTime? createdAtUtc,
  }) =>
      YildiznameResultPresentationBuild.unscoped(
        title: title,
        sections: sections,
        planets: planets,
        artifactId: artifactId,
        createdAtUtc: createdAtUtc,
      );

  final YildiznameResultSource source;
  final YildiznameResultScope scope;
  final String title;
  final List<StarMapResultSection> sections;
  final List<StarMapPlanetInfluence> planets;
  final YildiznameScopeDisclosure? scopeDisclosure;
  final String? artifactId;
  final DateTime? createdAtUtc;
  final String? chromeLanguage;
  final YildiznameFactSnapshot factSnapshot;
  final YildiznameContinuityPresentation continuity;

  /// Phase 7C forensic freeze. Production leaves this false.
  final bool forensicFlatSections;
  bool get isHistoricalArtifact => source.isArtifact;

  YildiznameResultPresentation withoutFactSnapshot() =>
      YildiznameResultPresentation(
        source: source,
        scope: scope,
        title: title,
        sections: sections,
        planets: planets,
        scopeDisclosure: scopeDisclosure,
        artifactId: artifactId,
        createdAtUtc: createdAtUtc,
        chromeLanguage: chromeLanguage,
        continuity: continuity,
        forensicFlatSections: forensicFlatSections,
      );

  YildiznameResultPresentation withoutRoleHierarchy() =>
      YildiznameResultPresentation(
        source: source,
        scope: scope,
        title: title,
        sections: sections,
        planets: planets,
        scopeDisclosure: scopeDisclosure,
        artifactId: artifactId,
        createdAtUtc: createdAtUtc,
        chromeLanguage: chromeLanguage,
        factSnapshot: factSnapshot,
        continuity: YildiznameContinuityPresentation.empty,
        forensicFlatSections: true,
      );

  YildiznameResultPresentation withContinuity(
    YildiznameContinuityPresentation value,
  ) =>
      YildiznameResultPresentation(
        source: source,
        scope: scope,
        title: title,
        sections: sections,
        planets: planets,
        scopeDisclosure: scopeDisclosure,
        artifactId: artifactId,
        createdAtUtc: createdAtUtc,
        chromeLanguage: chromeLanguage,
        factSnapshot: factSnapshot,
        continuity: value,
        forensicFlatSections: forensicFlatSections,
      );

  @override
  bool operator ==(Object other) =>
      other is YildiznameResultPresentation &&
      _presentationEquals(this, other);

  @override
  int get hashCode => _presentationHash(this);
}
