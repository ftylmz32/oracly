/// [AdsSdkPort] over google_mobile_ads (UMP + Mobile Ads SDK). Constructing
/// it touches nothing; every SDK call happens only when the gate asks.
library;

import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads_sdk_port.dart';

class GoogleMobileAdsPort implements AdsSdkPort {
  const GoogleMobileAdsPort();

  @override
  Future<void> requestConsentInfoUpdate() {
    final done = Completer<void>();
    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () {
          if (!done.isCompleted) done.complete();
        },
        (error) {
          if (!done.isCompleted) {
            done.completeError(
              AdsSdkException('consent_update', '${error.errorCode}'),
            );
          }
        },
      );
    } catch (error) {
      if (!done.isCompleted) {
        done.completeError(AdsSdkException('consent_update', '$error'));
      }
    }
    return done.future;
  }

  @override
  Future<void> loadAndShowConsentFormIfRequired() async {
    FormError? failure;
    try {
      await ConsentForm.loadAndShowConsentFormIfRequired((error) {
        failure = error;
      });
    } catch (error) {
      throw AdsSdkException('consent_form', '$error');
    }
    if (failure case final error?) {
      throw AdsSdkException('consent_form', '${error.errorCode}');
    }
  }

  @override
  Future<bool> canRequestAds() => ConsentInformation.instance.canRequestAds();

  @override
  Future<bool> privacyOptionsRequired() async =>
      await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
      PrivacyOptionsRequirementStatus.required;

  @override
  Future<void> showPrivacyOptionsForm() async {
    FormError? failure;
    try {
      await ConsentForm.showPrivacyOptionsForm((error) {
        failure = error;
      });
    } catch (error) {
      throw AdsSdkException('privacy_options', '$error');
    }
    if (failure case final error?) {
      throw AdsSdkException('privacy_options', '${error.errorCode}');
    }
  }

  @override
  Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();
    } catch (error) {
      throw AdsSdkException('initialize', '$error');
    }
  }
}
