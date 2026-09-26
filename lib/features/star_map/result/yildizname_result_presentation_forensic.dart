/// Test-only forensic presentation mutators (frozen phase goldens).
part of 'yildizname_result_presentation.dart';

extension YildiznameResultPresentationForensic on YildiznameResultPresentation {
  YildiznameResultPresentation withoutFactSnapshot() => _copy(
        factSnapshot: YildiznameFactSnapshot.empty,
      );

  YildiznameResultPresentation withoutRoleHierarchy() => _copy(
        continuity: YildiznameContinuityPresentation.empty,
        forensicFlatSections: true,
        forensicLegacyActionOrder: true,
        forensicHideHistoricalStatus: true,
      );

  /// Freeze pre-7E footer order without flattening body chrome.
  YildiznameResultPresentation withForensicActionOrder() => _copy(
        forensicLegacyActionOrder: true,
        forensicHideHistoricalStatus: true,
      );

  /// Hide historical reopen chrome for frozen 7A–7F expected-delta goldens.
  @visibleForTesting
  YildiznameResultPresentation withForensicHideHistoricalStatus() => _copy(
        forensicHideHistoricalStatus: true,
      );
}
