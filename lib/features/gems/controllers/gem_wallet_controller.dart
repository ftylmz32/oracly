/// UI-facing gem wallet — one notifier for every screen.
library;

import 'package:flutter/foundation.dart';

import '../copy/gems_copy.dart';
import '../data/gem_display.dart';
import '../models/gem_transaction.dart';
import '../services/gem_wallet_service.dart';

enum GemWalletHydrationState { loading, stale, authoritative, error }

class GemWalletController extends ChangeNotifier {
  GemWalletController(this._service) {
    _balance = _service.cachedBalance;
    _history = _service.history;
    _hydrationState = _balance == null
        ? GemWalletHydrationState.loading
        : GemWalletHydrationState.stale;
  }

  final GemWalletService _service;

  int? _balance;
  List<GemTransaction> _history = const [];
  bool _busy = false;
  bool _stale = true;
  late GemWalletHydrationState _hydrationState;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  int get balance => _balance ?? 0;
  int? get displayBalance => _balance;
  String get formatted => _balance == null ? '—' : GemDisplay.format(_balance!);
  List<GemTransaction> get history => _history;
  bool get busy => _busy || _service.busy;
  bool get stale => _stale;
  GemWalletHydrationState get hydrationState => _hydrationState;
  bool get authoritative =>
      _hydrationState == GemWalletHydrationState.authoritative;
  String? get ownerId => _service.ownerId;

  bool canSpend(int amount) => !_busy && _service.canSpend(amount);

  Future<void> reload() async {
    await reloadAuthoritatively();
  }

  /// Returns true only when this exact reload obtained a fresh server
  /// balance. Used by the hydration coordinator to let a recreated
  /// same-owner controller join one in-flight GET without replaying an
  /// old coordinator-cached number.
  Future<bool> reloadAuthoritatively() async {
    if (_busy) return authoritative;
    _busy = true;
    _hydrationState = _balance == null
        ? GemWalletHydrationState.loading
        : GemWalletHydrationState.stale;
    _safeNotify();
    try {
      final refreshed = await _service.refresh();
      if (refreshed == null) {
        _hydrationState = _service.canHydrate
            ? GemWalletHydrationState.error
            : (_balance == null
                  ? GemWalletHydrationState.loading
                  : GemWalletHydrationState.stale);
        return false;
      }
      _balance = refreshed;
      _history = _service.history;
      _stale = _service.stale;
      _hydrationState = GemWalletHydrationState.authoritative;
      return true;
    } catch (_) {
      _stale = true;
      _hydrationState = GemWalletHydrationState.error;
      return false;
    } finally {
      _busy = false;
      _safeNotify();
    }
  }

  /// Adopts the owner-bound durable cache currently held by this controller's
  /// service without issuing another GET or re-writing disk. Call only after
  /// a shared same-owner in-flight hydration has just succeeded.
  bool acceptHydratedCachedBalance() {
    final cached = _service.acceptHydratedCachedBalance();
    if (cached == null) return false;
    _balance = cached;
    _history = _service.history;
    _stale = _service.stale;
    _hydrationState = GemWalletHydrationState.authoritative;
    _safeNotify();
    return true;
  }

  Future<void> acceptAuthoritativeBalance(int balance) async {
    await _service.acceptAuthoritativeBalance(balance);
    _balance = _service.balance;
    _stale = _service.stale;
    _hydrationState = GemWalletHydrationState.authoritative;
    _safeNotify();
  }

  Future<bool> earn({required int amount, required String reason}) async {
    // Dead legacy API — production uses purpose-specific server commands.
    assert(false, 'GemWalletController.earn is not a production path');
    return false;
  }

  Future<bool> spend({required int amount, required String reason}) async {
    // Dead legacy API — production uses settleTarot / paid AI coordinators.
    assert(false, 'GemWalletController.spend is not a production path');
    return false;
  }

  String get insufficientMessage => GemsCopy.insufficient;
}
