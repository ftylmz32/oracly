/// Typed Yıldızname result presentation — the one contract the canonical
/// result screen renders.
library;

import 'package:flutter/foundation.dart';

import '../../ai/oracle_conversation/models/oracle_reading_context.dart';
import '../models/star_map_reading.dart';
import '../presentation/reference/star_map_result_section.dart';
import 'yildizname_continuity_presentation.dart';
import 'yildizname_fact_snapshot.dart';
import 'yildizname_historical_status.dart';
import 'yildizname_result_actions.dart';
import 'yildizname_result_actions_builder.dart';
import 'yildizname_result_presentation_build.dart';
import 'yildizname_result_types.dart';
import 'yildizname_scope_disclosure.dart';

export 'yildizname_historical_status.dart';
export 'yildizname_scope_disclosure.dart';

part 'yildizname_result_presentation_eq.dart';
part 'yildizname_result_presentation_copy.dart';
part 'yildizname_result_presentation_forensic.dart';

@immutable
final class YildiznameResultPresentation {
  YildiznameResultPresentation({
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
    this.forensicLegacyActionOrder = false,
    this.forensicHideHistoricalStatus = false,
    YildiznameResultActions? actions,
  }) : actions = actions ?? YildiznameResultActions.empty;

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
  final bool forensicFlatSections;

  /// Test-only: pre-7E footer order for frozen 7A–7C goldens.
  final bool forensicLegacyActionOrder;

  /// Test-only: hide historical chrome so frozen 7A–7F goldens stay byte-stable.
  @visibleForTesting
  final bool forensicHideHistoricalStatus;
  final YildiznameResultActions actions;

  bool get isHistoricalArtifact => source.isArtifact;

  /// Display-ready historical reopen chrome — null for live / fail-closed.
  YildiznameHistoricalStatus? get historicalStatus {
    if (forensicHideHistoricalStatus) return null;
    return YildiznameHistoricalStatus.tryOf(
      source: source,
      createdAtUtc: createdAtUtc,
      languageCode: chromeLanguage,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is YildiznameResultPresentation &&
      _presentationEquals(this, other);

  @override
  int get hashCode => _presentationHash(this);
}
