/// The single place that decides whether an ad may be requested.
///
/// Fail-closed order, re-checked after every asynchronous step:
///   rollout off → unsupported platform → app id not configured or
///   release not approved →
///   membership not verified free (loading, busy, error, unverified,
///   store unavailable) → Premium → consent (UMP) → SDK start → ready.
///
/// Nothing here runs on its own. Entry points:
///   * [armLaunchConsentRefresh] — Google's UMP guidance: refresh consent
///     information on every app launch. Armed once per launch (and per
///     account) from the app root; it runs [prepare] WITHOUT a form, and
///     only once every blocker has cleared (never with the flag off, never
///     for Premium, never while membership is unknown).
///   * [presentConsentFormAtSafeMoment] — the initial UMP consent form
///     (`loadAndShowConsentFormIfRequired`), shown only when UMP reports
///     consent as required, at most once per gate, and only from
///     AdsConsentMomentHost (home tab root, nothing pushed above it, app
///     resumed) — never over a reading, a capture or a purchase.
///   * [showPrivacyOptions] — the separate, user-opened privacy options form
///     (`showPrivacyOptionsForm`) from the Privacy Control Center.
/// Both forms share one [AdsConsentFormLock]: two UMP forms never open at
/// once, across accounts too. No ad is ever loaded here. The daily free
/// reading allowance never depends on this gate.
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

/// Process-wide guard: at most one UMP form (consent or privacy options)
/// is open at a time. Shared by every gate (one per account).
class AdsConsentFormLock {
  bool _held = false;

  bool get held => _held;

  bool tryAcquire() {
    if (_held) return false;
    _held = true;
    return true;
  }

  void release() => _held = false;
}

class AdsGate extends ChangeNotifier {
  AdsGate({
    required AdsSdkPort port,
    required PremiumStatusController premium,
    required bool Function() rolloutEnabled,
    required AdsEnvironment environment,
    AdsConsentFormLock? formLock,
    this.stepTimeout = const Duration(seconds: 12),
  }) : _port = port,
       _premium = premium,
       _rolloutEnabled = rolloutEnabled,
       _environment = environment,
       _formLock = formLock ?? AdsConsentFormLock() {
    _premium.addListener(_onMembershipChanged);
  }

  final AdsSdkPort _port;
  final PremiumStatusController _premium;
  final bool Function() _rolloutEnabled;
  final AdsEnvironment _environment;
  final AdsConsentFormLock _formLock;
  final Duration stepTimeout;

  AdsGateStatus _status = AdsGateStatus.idle;
  bool _sdkStarted = false;
  bool _privacyOptionsRequired = false;
  bool _consentFormPending = false;
  bool _consentFormAttempted = false;
  bool _disposed = false;
  Future<AdsGateStatus>? _inFlight;
  bool _inFlightUserInitiated = false;
  bool _launchRefreshArmed = false;
  bool _launchRefreshStarted = false;

  AdsGateStatus get status => _status;

  /// Whether UMP asks for a privacy-options entry point (known only after
  /// a consent refresh in this session).
  bool get privacyOptionsRequired => _privacyOptionsRequired;

  /// UMP reported consent as REQUIRED and the initial form has not been
  /// shown by this gate yet; the safe-moment host may present it.
  bool get consentFormPending =>
      !_disposed &&
      _consentFormPending &&
      !_consentFormAttempted &&
      _blocker() == null;

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

  /// Walks the gate. [userInitiated] allows UMP's initial consent form
  /// (only from a safe moment — see [presentConsentFormAtSafeMoment]).
  /// Concurrent calls share one run.
  Future<AdsGateStatus> prepare({bool userInitiated = false}) {
    final running = _inFlight;
    if (running != null) {
      // A form-allowed call must not be swallowed by a launch refresh that
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

  /// Shows UMP's initial consent form once, only if UMP reported consent as
  /// required and no other UMP form is open. Returns whether it ran.
  Future<bool> presentConsentFormAtSafeMoment() async {
    if (!consentFormPending || _formLock.held || _inFlight != null) {
      return false;
    }
    _consentFormAttempted = true;
    await prepare(userInitiated: true);
    return true;
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
    if (_changed()) return _closedByChange();
    _consentFormPending = await _consentStatus() == AdsConsentStatus.required;
    if (_changed()) return _closedByChange();

    if (userInitiated && _consentFormPending) {
      if (!_formLock.tryAcquire()) {
        // Another UMP form is open: never stack a second one.
        return _set(AdsGateStatus.consentNotGranted);
      }
      try {
        await _port.loadAndShowConsentFormIfRequired().timeout(
          const Duration(minutes: 10),
        );
      } catch (_) {
        return _set(AdsGateStatus.consentFailed);
      } finally {
        _formLock.release();
      }
      // A late form result (account switched, became Premium, flag off)
      // never starts the SDK.
      if (_changed()) return _closedByChange();
      _consentFormPending = await _consentStatus() == AdsConsentStatus.required;
      if (_changed()) return _closedByChange();
    }

    _privacyOptionsRequired = await _safe(_port.privacyOptionsRequired);
    final allowed = await _safe(_port.canRequestAds);
    if (_changed()) return _closedByChange();
    if (!allowed) return _set(AdsGateStatus.consentNotGranted);

    if (!_sdkStarted) {
      try {
        await _port.initialize().timeout(stepTimeout);
        _sdkStarted = true;
      } catch (_) {
        return _set(AdsGateStatus.sdkFailed);
      }
      if (_changed()) return _closedByChange();
    }
    return _set(AdsGateStatus.ready);
  }

  /// Opens UMP's privacy options (re-consent / withdraw) — separate from
  /// the initial consent form, user-opened only, never while another UMP
  /// form is open. Re-evaluates afterwards: withdrawn consent drops the
  /// gate out of [ready]; newly granted consent re-walks the gate (no form).
  Future<bool> showPrivacyOptions() async {
    if (_disposed || !_rolloutEnabled()) return false;
    if (!_formLock.tryAcquire()) return false;
    try {
      await _port.showPrivacyOptionsForm();
    } catch (_) {
      return false;
    } finally {
      _formLock.release();
    }
    if (_disposed) return true;
    final allowed = await _safe(_port.canRequestAds);
    if (_disposed) return true;
    if (!allowed) {
      if (_status == AdsGateStatus.ready) {
        _set(AdsGateStatus.consentNotGranted);
      }
    } else if (_status != AdsGateStatus.ready && _blocker() == null) {
      unawaited(prepare());
    }
    return true;
  }

  bool _changed() => _disposed || _blocker() != null;

  AdsGateStatus _closedByChange() =>
      _set(_disposed ? AdsGateStatus.off : (_blocker() ?? AdsGateStatus.off));

  Future<AdsConsentStatus> _consentStatus() async {
    try {
      return await _port.consentStatus().timeout(stepTimeout);
    } catch (_) {
      return AdsConsentStatus.unknown;
    }
  }

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
