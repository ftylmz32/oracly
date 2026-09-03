/// Authoritative Free / Premium runtime status — commerce entitlement only.
library;

import 'package:flutter/foundation.dart';

import '../../../core/domain/models/premium_plan.dart';
import '../../../core/services/premium_service.dart';
import '../models/premium_entitlement_state.dart';
import '../models/premium_purchase_result.dart';

class PremiumStatusController extends ChangeNotifier {
  PremiumStatusController(this._service);

  final PremiumService _service;
  bool _loaded = false;
  PremiumEntitlementState _entitlement = PremiumEntitlementState.inactive;
  String? _entitlementMessage;
  PremiumPlanKind _selectedPlan = PremiumPlanKind.yearly;
  PremiumPlanKind? _activePlan;
  List<PremiumPlanModel> _plans = const [];

  bool get loaded => _loaded;
  PremiumEntitlementState get entitlement => _entitlement;
  String? get entitlementMessage => _entitlementMessage;
  bool get isPremium => _entitlement.allowsPremiumFeatures;
  bool get isFree => !isPremium;
  bool get busy => _entitlement.isTransient;
  bool get purchaseConfigured => _service.purchaseConfigured;
  PremiumPlanKind get selectedPlan => _selectedPlan;
  PremiumPlanKind? get activePlan => _activePlan;
  List<PremiumPlanModel> get plans => _plans;

  Future<void> load() async {
    try {
      await _service.preparePurchase();
      _activePlan = await _service.activePlan();
      _plans = await _service.getPlans();
      if (_activePlan != null) _selectedPlan = _activePlan!;
      await _reconcile(keepActiveWhileRefreshing: true);
      _loaded = true;
    } catch (_) {
      _fail(PremiumPurchaseResult.failed().message);
      _loaded = true;
    }
    notifyListeners();
  }

  Future<void> refresh() => load();

  void selectPlan(PremiumPlanKind kind) {
    if (isPremium || busy) return;
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
    _set(PremiumEntitlementState.pending,
        PremiumPurchaseResult.pending().message);
    try {
      final result = await _service.purchase(_selectedPlan);
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
    _set(PremiumEntitlementState.restoring,
        PremiumPurchaseResult.pending().message);
    try {
      final result = await _service.restore();
      await _settle(result);
      return result;
    } catch (_) {
      _fail(PremiumPurchaseResult.restoreFailed().message);
      return PremiumPurchaseResult.restoreFailed();
    }
  }

  Future<void> _reconcile({required bool keepActiveWhileRefreshing}) async {
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
  }

  Future<void> _settle(PremiumPurchaseResult result) async {
    if (result.granted) {
      await load();
      return;
    }
    switch (result.outcome) {
      case PremiumPurchaseOutcome.pending:
        await _reconcile(keepActiveWhileRefreshing: false);
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
        await _reconcile(keepActiveWhileRefreshing: false);
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
