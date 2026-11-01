/// The single place that decides whether an ad may be requested.
///
/// Fail-closed order, re-checked after every asynchronous step:
///   rollout off → unsupported platform → app id not configured or
///   release not approved →
///   membership not verified free (loading, busy, error, unverified,
///   store unavailable) → Premium → consent (UMP) → SDK start → ready.
///
/// Nothing here runs on its own. Two entry points exist:
///   * [armLaunchConsentRefresh] — Google's UMP guidance: refresh consent
///     information on every app launch. Armed once per launch (and per
///     account) from the app root; it runs [prepare] without the consent
///     form, and only once every blocker has cleared (so never with the
///     flag off, never for Premium, never while membership is unknown).
///   * [prepare] with userInitiated — the only path that may show the UMP
///     consent form; no ad placement calls it yet in this phase.
/// No ad is ever loaded here. The daily free reading allowance never
/// depends on this gate.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../premium/controllers/premium_status_controller.dart';
import '../../premium/models/premium_entitlement_state.dart';
import '../ads_environment.dart';
import '../services/ads_sdk_port.dart';

enum AdsGateStatus {
  /// Not prepared yet (or reset); nothing has been asked of the SDK.
  idle,

  /// Rollout flag off: the SDK is never touched.
  off,

  /// Not Android / iOS.
  unsupportedPlatform,

  /// No real AdMob app id, or a release build without the explicit
  /// production-ads approval (ORACLY_ADS_RELEASE_APPROVED).
  notConfigured,

  /// Membership not verified as free: never risk an ad to a member.
  membershipUnknown,

  /// Verified Premium (or reviewer access): no ads, ever.
  premium,

  /// Consent information could not be refreshed or the form failed.
  consentFailed,

  /// UMP does not allow ad requests (consent not given / not yet asked).
  consentNotGranted,

  /// The Mobile Ads SDK failed to start.
  sdkFailed,

  /// Every condition holds; an ad request may be made right now.
  ready,
}

class AdsGate extends ChangeNotifier {
  AdsGate({
    required AdsSdkPort port,
    required PremiumStatusController premium,
    required bool Function() rolloutEnabled,
    required AdsEnvironment environment,
    this.stepTimeout = const Duration(seconds: 12),
  }) : _port = port,
       _premium = premium,
       _rolloutEnabled = rolloutEnabled,
       _environment = environment {
    _premium.addListener(_onMembershipChanged);
  }

  final AdsSdkPort _port;
  final PremiumStatusController _premium;
  final bool Function() _rolloutEnabled;
  final AdsEnvironment _environment;
  final Duration stepTimeout;

  AdsGateStatus _status = AdsGateStatus.idle;
  bool _sdkStarted = false;
  bool _privacyOptionsRequired = false;
  bool _disposed = false;
  Future<AdsGateStatus>? _inFlight;
  bool _inFlightUserInitiated = false;
  bool _launchRefreshArmed = false;
  bool _launchRefreshStarted = false;

  AdsGateStatus get status => _status;

  /// Whether UMP asks for a privacy-options entry point (known only after
  /// a consent refresh in this session).
  bool get privacyOptionsRequired => _privacyOptionsRequired;

  /// Checked immediately before every ad request: the last preparation
  /// succeeded AND nothing has changed since (flag, membership).
  bool get canRequestAds =>
      !_disposed && _status == AdsGateStatus.ready && _blocker() == null;

  /// The reason no ad may be requested, before any SDK call; null = none.
  AdsGateStatus? _blocker() {
    if (!_rolloutEnabled()) return AdsGateStatus.off;
    if (!_environment.supportedPlatform) {
      return AdsGateStatus.unsupportedPlatform;
    }
    if (!_environment.appIdConfigured || !_environment.releaseApproved) {
      return AdsGateStatus.notConfigured;
    }
    if (_premium.isPremium) return AdsGateStatus.premium;
    if (!_premium.loaded ||
        _premium.busy ||
        _premium.entitlement != PremiumEntitlementState.inactive) {
      return AdsGateStatus.membershipUnknown;
    }
    return null;
  }

  /// Walks the gate. [userInitiated] lets UMP show its consent form (only
  /// from a natural, user-started moment — never at launch, never over a
  /// reading, a capture or a purchase). Concurrent calls share one run.
  Future<AdsGateStatus> prepare({bool userInitiated = false}) {
    final running = _inFlight;
    if (running != null) {
      // A user-started call must not be swallowed by a launch refresh that
      // skips the form: let that run finish, then walk again with the form.
      if (userInitiated && !_inFlightUserInitiated) {
        return running.then((_) => prepare(userInitiated: true));
      }
      return running;
    }
    _inFlightUserInitiated = userInitiated;
    return _inFlight = _prepare(userInitiated).whenComplete(() {
      _inFlight = null;
      _inFlightUserInitiated = false;
    });
  }

  /// UMP: request a consent-information update on every app launch. Arms a
  /// single refresh (no consent form) that runs as soon as no blocker
  /// remains — immediately, or when membership becomes verified free.
  /// Flag off / Premium / unknown membership / not configured: no SDK call.
  void armLaunchConsentRefresh() {
    if (_disposed) return;
    _launchRefreshArmed = true;
    _maybeRunLaunchRefresh();
  }

  void _maybeRunLaunchRefresh() {
    if (!_launchRefreshArmed || _launchRefreshStarted || _disposed) return;
    if (_blocker() != null) return;
    _launchRefreshStarted = true;
    unawaited(prepare());
  }

  Future<AdsGateStatus> _prepare(bool userInitiated) async {
    final blocked = _blocker();
    if (blocked != null) return _set(blocked);

    try {
      await _port.requestConsentInfoUpdate().timeout(stepTimeout);
    } catch (_) {
      // Network / UMP failure: no ads this session rather than guessing.
      return _set(AdsGateStatus.consentFailed);
    }
    if (_changed()) return _set(_blocker()!);

    if (userInitiated) {
      try {
        await _port.loadAndShowConsentFormIfRequired().timeout(
          const Duration(minutes: 10),
        );
      } catch (_) {
        return _set(AdsGateStatus.consentFailed);
      }
      if (_changed()) return _set(_blocker()!);
    }

    _privacyOptionsRequired = await _safe(_port.privacyOptionsRequired);
    final allowed = await _safe(_port.canRequestAds);
    if (_changed()) return _set(_blocker()!);
    if (!allowed) return _set(AdsGateStatus.consentNotGranted);

    if (!_sdkStarted) {
      try {
        await _port.initialize().timeout(stepTimeout);
        _sdkStarted = true;
      } catch (_) {
        return _set(AdsGateStatus.sdkFailed);
      }
      if (_changed()) return _set(_blocker()!);
    }
    return _set(AdsGateStatus.ready);
  }

  /// Opens UMP's privacy options (re-consent / withdraw). Re-evaluates
  /// afterwards: withdrawn consent drops the gate out of [ready].
  Future<bool> showPrivacyOptions() async {
    if (_disposed || !_rolloutEnabled()) return false;
    try {
      await _port.showPrivacyOptionsForm();
    } catch (_) {
      return false;
    }
    final allowed = await _safe(_port.canRequestAds);
    if (!_disposed && !allowed && _status == AdsGateStatus.ready) {
      _set(AdsGateStatus.consentNotGranted);
    }
    return true;
  }

  bool _changed() => _disposed || _blocker() != null;

  Future<bool> _safe(Future<bool> Function() call) async {
    try {
      return await call().timeout(stepTimeout);
    } catch (_) {
      return false;
    }
  }

  void _onMembershipChanged() {
    _maybeRunLaunchRefresh();
    if (_status != AdsGateStatus.ready) return;
    final blocked = _blocker();
    if (blocked != null) _set(blocked);
  }

  AdsGateStatus _set(AdsGateStatus value) {
    if (_disposed) return AdsGateStatus.off;
    if (_status != value) {
      _status = value;
      notifyListeners();
    }
    return value;
  }

  @override
  void dispose() {
    _disposed = true;
    _premium.removeListener(_onMembershipChanged);
    super.dispose();
  }
}
