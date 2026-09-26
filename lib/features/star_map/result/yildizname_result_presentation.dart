/// Typed Yıldızname result presentation — the one contract the canonical
/// result screen renders.
library;

import 'package:flutter/foundation.dart';

import '../../ai/oracle_conversation/models/oracle_reading_context.dart';
import '../models/star_map_reading.dart';
import '../presentation/reference/star_map_result_section.dart';
import 'yildizname_continuity_presentation.dart';
import 'yildizname_fact_snapshot.dart';
import 'yildizname_result_actions.dart';
import 'yildizname_result_actions_builder.dart';
import 'yildizname_result_presentation_build.dart';
import 'yildizname_result_types.dart';
import 'yildizname_scope_disclosure.dart';

export 'yildizname_scope_disclosure.dart';

part 'yildizname_result_presentation_eq.dart';

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
  final YildiznameResultActions actions;
  bool get isHistoricalArtifact => source.isArtifact;

  YildiznameResultPresentation withoutFactSnapshot() => _copy(
        factSnapshot: YildiznameFactSnapshot.empty,
      );

  YildiznameResultPresentation withoutRoleHierarchy() => _copy(
        continuity: YildiznameContinuityPresentation.empty,
        forensicFlatSections: true,
        forensicLegacyActionOrder: true,
      );

  /// Freeze pre-7E footer order without flattening body chrome.
  YildiznameResultPresentation withForensicActionOrder() => _copy(
        forensicLegacyActionOrder: true,
      );

  YildiznameResultPresentation withContinuity(
    YildiznameContinuityPresentation value,
  ) =>
      _copy(continuity: value);

  YildiznameResultPresentation withActions(YildiznameResultActions value) =>
      _copy(actions: value);

  /// Attach actions derived from this presentation (+ optional OR context).
  YildiznameResultPresentation withBuiltActions({
    OracleReadingContext? orContext,
  }) =>
      withActions(
        YildiznameResultActionsBuilder.build(
          presentation: this,
          orContext: orContext,
        ),
      );

  YildiznameResultPresentation _copy({
    YildiznameFactSnapshot? factSnapshot,
    YildiznameContinuityPresentation? continuity,
    bool? forensicFlatSections,
    bool? forensicLegacyActionOrder,
    YildiznameResultActions? actions,
  }) =>
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
        factSnapshot: factSnapshot ?? this.factSnapshot,
        continuity: continuity ?? this.continuity,
        forensicFlatSections: forensicFlatSections ?? this.forensicFlatSections,
        forensicLegacyActionOrder:
            forensicLegacyActionOrder ?? this.forensicLegacyActionOrder,
        actions: actions ?? this.actions,
      );

  @override
  bool operator ==(Object other) =>
      other is YildiznameResultPresentation &&
      _presentationEquals(this, other);

  @override
  int get hashCode => _presentationHash(this);
}
