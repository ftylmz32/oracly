/// Authoritative Free / Premium runtime status — commerce entitlement only.
library;

import 'package:flutter/foundation.dart';

import '../../../core/domain/models/premium_plan.dart';
import '../../../core/services/premium_service.dart';
import '../models/premium_entitlement_state.dart';
import '../models/premium_purchase_result.dart';
import '../models/review_access_result.dart';
import '../services/premium_plan_availability.dart';
import 'premium_reconcile_freshness.dart';

class PremiumStatusController extends ChangeNotifier {
  PremiumStatusController(this._service, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final PremiumService _service;
  final DateTime Function() _now;
  final PremiumReconcileFreshness _freshness = PremiumReconcileFreshness();
  bool _loaded = false;
  PremiumEntitlementState _entitlement = PremiumEntitlementState.inactive;
  String? _entitlementMessage;
  PremiumPlanKind _selectedPlan = PremiumPlanKind.yearly;
  PremiumPlanKind? _activePlan;
  List<PremiumPlanModel> _plans = const [];
  bool _reviewAccessActive = false;

  /// R3.1 — definitive-only freshness window (see [PremiumReconcileFreshness]).
  @visibleForTesting
  static const freshnessWindow = PremiumReconcileFreshness.freshnessWindow;

  /// R3.1 — transient retry throttle (not entitlement freshness).
  @visibleForTesting
  static const retryThrottle = PremiumReconcileFreshness.retryThrottle;

  Future<void>? _inFlight;
  Future<void>? _loadInFlight;

  /// True only after a *definitive* reconcile within [freshnessWindow].
  bool get isFresh => _freshness.isFresh(_now());

  @visibleForTesting
  bool get hasInFlightReconcile => _inFlight != null;

  @visibleForTesting
  DateTime? get lastDefinitiveReconciledAt => _freshness.lastDefinitiveAt;

  @visibleForTesting
  DateTime? get lastReconcileAttemptAt => _freshness.lastAttemptAt;

  bool get loaded => _loaded;
  PremiumEntitlementState get entitlement => _entitlement;
  String? get entitlementMessage => _entitlementMessage;

  /// Commerce entitlement OR an active Play/App Store reviewer grant —
  /// distinguishable via [isReviewAccessActive]; never written back into
  /// [entitlement], and never mixed with purchase credentials.
  bool get isPremium =>
      _entitlement.allowsPremiumFeatures || _reviewAccessActive;
  bool get isReviewAccessActive => _reviewAccessActive;
  bool get isFree => !isPremium;
  bool get busy => _entitlement.isTransient;
  bool get purchaseConfigured => _service.purchaseConfigured;
  bool get ownerAccessReady => _service.ownerAccessReady;
  bool get canAttemptRestore => _service.canAttemptRestore;
  PremiumPlanKind get selectedPlan => _selectedPlan;
  PremiumPlanKind? get activePlan => _activePlan;
  List<PremiumPlanModel> get plans => _plans;

  Future<void> load() {
    final existing = _loadInFlight;
    if (existing != null) return existing;
    final future = _loadOnce().whenComplete(() {
      _loadInFlight = null;
    });
    _loadInFlight = future;
    return future;
  }

  Future<void> _loadOnce() async {
    try {
      await _service.preparePurchase();
      _activePlan = await _service.activePlan();
      _plans = PremiumPlanAvailability.visiblePlans(await _service.getPlans());
      if (_activePlan != null &&
          PremiumPlanAvailability.isPurchasable(_activePlan!)) {
        _selectedPlan = _activePlan!;
      } else {
        _selectedPlan = PremiumPlanAvailability.normalizeSelection(
          _selectedPlan,
        );
      }
      await _guardedReconcile(keepActiveWhileRefreshing: true);
      _loaded = true;
    } catch (_) {
      _fail(PremiumPurchaseResult.failed().message);
      _loaded = true;
    }
    notifyListeners();
  }

  Future<void> refresh() => load();

  /// R3.1 — Premium-gated / resume preflight. Trusts definitive freshness;
  /// after a transient failure, respects [retryThrottle] before retrying.
  Future<void> ensureFresh() async {
    if (!_loaded) {
      await load();
      return;
    }
    if (isFresh) return;
    if (_freshness.isRetryThrottled(_now())) return;
    await _guardedReconcile(keepActiveWhileRefreshing: true);
    notifyListeners();
  }

  /// R3.1 — bypass definitive freshness + retry throttle after a definite
  /// server entitlement denial. Still single-flight.
  Future<void> forceReconcile() async {
    _freshness.bypassCaches();
    if (!_loaded) {
      await load();
      return;
    }
    await _guardedReconcile(keepActiveWhileRefreshing: true);
    notifyListeners();
  }

  /// R3 — single-flight: concurrent callers share one in-flight reconcile.
  Future<void> _guardedReconcile({required bool keepActiveWhileRefreshing}) {
    final existing = _inFlight;
    if (existing != null) return existing;
    final future =
        _reconcile(keepActiveWhileRefreshing: keepActiveWhileRefreshing)
            .then((definitive) {
              _freshness.recordAttempt(definitive: definitive, now: _now());
            })
            .whenComplete(() {
              _inFlight = null;
            });
    _inFlight = future;
    return future;
  }

  void selectPlan(PremiumPlanKind kind) {
    if (isPremium || busy) return;
    if (!PremiumPlanAvailability.isPurchasable(kind)) return;
    _selectedPlan = kind;
    notifyListeners();
  }

  Future<PremiumPurchaseResult> purchase() async {
    if (isPremium) return PremiumPurchaseResult.granted(_selectedPlan);
    if (!_service.purchaseConfigured) {
      _set(PremiumEntitlementState.unavailable);
      return PremiumPurchaseResult.unavailable();
    }
    if (!_entitlement.canStartPurchase) {
      return PremiumPurchaseResult.unavailable();
    }
    final plan = PremiumPlanAvailability.normalizeSelection(_selectedPlan);
    if (plan != _selectedPlan) {
      _selectedPlan = plan;
      notifyListeners();
    }
    if (!PremiumPlanAvailability.isPurchasable(plan)) {
      return PremiumPurchaseResult.unavailable();
    }
    _set(
      PremiumEntitlementState.pending,
      PremiumPurchaseResult.pending().message,
    );
    try {
      final result = await _service.purchase(plan);
      await _settle(result);
      return result;
    } catch (_) {
      _fail(PremiumPurchaseResult.failed().message);
      return PremiumPurchaseResult.failed();
    }
  }

  Future<PremiumPurchaseResult> restore() async {
    if (_entitlement.isTransient) {
      return PremiumPurchaseResult.restoreUnavailable();
    }
    // Restore needs store/plugin availability, not a loaded product catalogue.
    if (!_service.canAttemptRestore) {
      _set(PremiumEntitlementState.unavailable);
      return PremiumPurchaseResult.restoreUnavailable();
    }
    _set(
      PremiumEntitlementState.restoring,
      PremiumPurchaseResult.pending().message,
    );
    try {
      final result = await _service.restore();
      await _settle(result);
      return result;
    } catch (_) {
      _fail(PremiumPurchaseResult.restoreFailed().message);
      return PremiumPurchaseResult.restoreFailed();
    }
  }

  /// Returns whether the reconcile conclusion was definitive.
  Future<bool> _reconcile({required bool keepActiveWhileRefreshing}) async {
    final wasActive =
        keepActiveWhileRefreshing &&
        _entitlement == PremiumEntitlementState.active &&
        _service.wasAuthoritativelyVerified;
    if (wasActive) {
      // Anti-flicker: keep active UI while refresh settles.
      _entitlement = PremiumEntitlementState.active;
      _entitlementMessage = null;
    }
    final snap = await _service.reconcile();
    _entitlement = snap.entitlement;
    _entitlementMessage = snap.message;
    // Review access is a fallback only — real commerce entitlement above
    // is untouched and always takes priority.
    _reviewAccessActive = _entitlement.allowsPremiumFeatures
        ? false
        : await _service.reviewAccessActive();
    return snap.definitive;
  }

  /// Submits a Play/App Store reviewer code. Never touches purchase
  /// credentials or commerce entitlement state. Returns the full
  /// [ReviewAccessResult] so the caller can distinguish a definitive "wrong
  /// code" denial from a transient network/server failure and word the
  /// message honestly instead of always saying the code is wrong.
  Future<ReviewAccessResult> activateReviewAccessResult(String code) async {
    final result = await _service.activateReviewAccessResult(code);
    if (result.granted) {
      _reviewAccessActive = true;
      notifyListeners();
    }
    return result;
  }

  /// Convenience wrapper over [activateReviewAccessResult] for callers that
  /// only care whether access was granted.
  Future<bool> activateReviewAccess(String code) async {
    return (await activateReviewAccessResult(code)).granted;
  }

  Future<void> _settle(PremiumPurchaseResult result) async {
    if (result.granted) {
      await load();
      return;
    }
    switch (result.outcome) {
      case PremiumPurchaseOutcome.pending:
        await _guardedReconcile(keepActiveWhileRefreshing: false);
        _entitlementMessage = result.message;
      case PremiumPurchaseOutcome.unavailable:
      case PremiumPurchaseOutcome.restoreUnavailable:
        _set(PremiumEntitlementState.unavailable, result.message);
      case PremiumPurchaseOutcome.failed:
      case PremiumPurchaseOutcome.restoreFailed:
        _fail(result.message);
      case PremiumPurchaseOutcome.unverified:
        _set(PremiumEntitlementState.unverified, result.message);
      case PremiumPurchaseOutcome.cancelled:
      case PremiumPurchaseOutcome.noneFound:
      case PremiumPurchaseOutcome.granted:
      case PremiumPurchaseOutcome.restored:
        await _guardedReconcile(keepActiveWhileRefreshing: false);
        _entitlementMessage = result.message;
    }
    notifyListeners();
  }

  void _set(PremiumEntitlementState next, [String? message]) {
    _entitlement = next;
    _entitlementMessage = message;
    notifyListeners();
  }

  void _fail(String message) {
    _entitlement = PremiumEntitlementState.error;
    _entitlementMessage = message;
    notifyListeners();
  }
}
