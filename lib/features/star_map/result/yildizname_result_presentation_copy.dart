/// Copy / action mutators for [YildiznameResultPresentation].
part of 'yildizname_result_presentation.dart';

extension YildiznameResultPresentationCopy on YildiznameResultPresentation {
  YildiznameResultPresentation withContinuity(
    YildiznameContinuityPresentation value,
  ) =>
      _copy(continuity: value);

  YildiznameResultPresentation withActions(YildiznameResultActions value) =>
      _copy(actions: value);

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
    bool? forensicHideHistoricalStatus,
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
        forensicHideHistoricalStatus: forensicHideHistoricalStatus ??
            this.forensicHideHistoricalStatus,
        actions: actions ?? this.actions,
      );
}
