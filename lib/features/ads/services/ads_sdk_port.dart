/// The only calls the ad gate makes into the ad SDK / UMP consent SDK.
/// Tests count them; production uses [GoogleMobileAdsPort].
library;

abstract interface class AdsSdkPort {
  /// Refreshes UMP consent information (a consent-status request, never an
  /// ad request). Throws [AdsSdkException] on failure.
  Future<void> requestConsentInfoUpdate();

  /// Shows the UMP consent form only if UMP says it is required.
  /// Throws [AdsSdkException] on failure.
  Future<void> loadAndShowConsentFormIfRequired();

  /// UMP's verdict on whether ads may be requested at all.
  Future<bool> canRequestAds();

  /// Whether UMP requires a privacy-options entry point.
  Future<bool> privacyOptionsRequired();

  /// Shows the UMP privacy-options form. Throws [AdsSdkException].
  Future<void> showPrivacyOptionsForm();

  /// Starts the Mobile Ads SDK. Throws [AdsSdkException] on failure.
  Future<void> initialize();
}

class AdsSdkException implements Exception {
  const AdsSdkException(this.stage, [this.detail]);

  final String stage;
  final String? detail;

  @override
  String toString() =>
      'AdsSdkException($stage${detail == null ? '' : ': $detail'})';
}
