/// Ad gate wiring. Reading [adsGateProvider] never calls the SDK; only
/// [AdsGate.prepare] does (directly, or via the launch consent refresh). A new gate per account (owner epoch), so one
/// account's readiness never carries over to the next. UMP consent is a
/// device-level choice and is deliberately not reset on account switch.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/backend_providers.dart';
import '../../premium/providers/premium_providers.dart';
import '../ads_environment.dart';
import '../ads_rollout.dart';
import '../controllers/ads_gate.dart';
import '../services/ads_sdk_port.dart';
import '../services/google_mobile_ads_port.dart';

final adsSdkPortProvider = Provider<AdsSdkPort>(
  (ref) => const GoogleMobileAdsPort(),
);

final adsEnvironmentProvider = Provider<AdsEnvironment>(
  (ref) => AdsEnvironment.current(),
);

final adsGateProvider = ChangeNotifierProvider<AdsGate>((ref) {
  ref.watch(localDataOwnerEpochProvider);
  return AdsGate(
    port: ref.watch(adsSdkPortProvider),
    premium: ref.watch(premiumStatusProvider.notifier),
    rolloutEnabled: () => AdsRollout.enabled,
    environment: ref.watch(adsEnvironmentProvider),
  );
});

/// Watched once by the app root (OraclyApp). Implements UMP's "refresh
/// consent information on every app launch" — and nothing else: no form,
/// no ad load. With the rollout off or the build not usable for ads (e.g. a
/// release without ORACLY_ADS_RELEASE_APPROVED) it returns before even
/// creating the gate, so the app's launch path is unchanged. Re-runs per
/// account because the gate is rebuilt on every owner epoch.
final adsLaunchConsentProvider = Provider<void>((ref) {
  if (!AdsRollout.enabled) return;
  if (!ref.watch(adsEnvironmentProvider).usable) return;
  ref.watch(adsGateProvider.notifier).armLaunchConsentRefresh();
});
