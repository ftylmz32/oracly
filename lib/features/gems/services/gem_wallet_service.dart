/// Server-authoritative wallet; local storage is a last-known display cache.
library;

// ignore_for_file: prefer_initializing_formals

import '../copy/gems_copy.dart';
import '../data/gem_wallet_store.dart';
import '../models/gem_transaction.dart';
import 'gem_wallet_gateway.dart';

class GemSpendException implements Exception {
  const GemSpendException(this.message);
  final String message;
}

class GemWalletService {
  GemWalletService(
    this._store, {
    GemWalletGateway? gateway,
    String? ownerId,
    bool requireOwner = false,
    String? Function()? currentOwnerId,
  }) : _gateway = gateway,
       ownerId = ownerId?.trim(),
       _requireOwner = requireOwner,
       _currentOwnerId = currentOwnerId;

  final GemWalletStore _store;
  final GemWalletGateway? _gateway;
  final String? ownerId;
  final bool _requireOwner;
  final String? Function()? _currentOwnerId;
  bool _busy = false;
  bool _stale = true;

  bool get busy => _busy;
  bool get stale => _stale;
  int? get cachedBalance =>
      _requireOwner ? _store.balanceForOwner(ownerId) : _store.balance();
  int get balance => cachedBalance ?? 0;
  bool get canHydrate =>
      _gateway != null &&
      (!_requireOwner ||
          (ownerId?.isNotEmpty == true && _ownerIsCurrent));
  List<GemTransaction> get history => _store.history();

  bool canSpend(int amount) =>
      amount > 0 &&
      !_busy &&
      !_stale &&
      (!_requireOwner || _ownerIsCurrent) &&
      balance >= amount;

  bool get _ownerIsCurrent {
    if (!_requireOwner) return true;
    final owner = ownerId;
    if (owner == null || owner.isEmpty) return false;
    final resolver = _currentOwnerId;
    if (resolver == null) return true;
    final live = resolver()?.trim();
    return live != null && live.isNotEmpty && live == owner;
  }

  Future<int?> refresh() => _locked(() async {
    if (!_ownerIsCurrent) return null;
    final result = await _gateway?.balance();
    return result == null ? null : _accept(result);
  });

  /// Accepts a balance returned by another authenticated wallet endpoint.
  /// This updates the display snapshot and performs no client arithmetic.
  Future<void> acceptAuthoritativeBalance(int balance) async {
    if (balance < 0) return;
    if (!_ownerIsCurrent) {
      throw const GemSpendException('owner_changed');
    }
    await _store.cacheServerBalance(balance, ownerId: ownerId);
    _stale = false;
  }

  Future<GemServerResult?> claimStarter({required String idempotencyKey}) =>
      _command((gateway) => gateway.starterGrant(idempotencyKey));

  Future<GemServerResult?> claimDaily({required String idempotencyKey}) =>
      _command((gateway) => gateway.dailyReward(idempotencyKey));

  Future<GemServerResult?> settleTarot({
    required String operationId,
    required String idempotencyKey,
  }) => _command((gateway) => gateway.settleTarot(operationId, idempotencyKey));

  Future<GemServerResult?> _command(
    Future<GemServerResult?> Function(GemWalletGateway gateway) run,
  ) => _locked(() async {
    if (!_ownerIsCurrent) return null;
    final gateway = _gateway;
    if (gateway == null) return null;
    final result = await run(gateway);
    if (result == null) return null;

    // The server command is authoritative. Once it returned a successful
    // settlement/reward envelope, a local display-cache failure must not
    // rewrite that server success into "command failed" — settlement retry is
    // idempotent, but UI/recovery still need to know the server accepted it.
    // Keep the wallet stale so a later reload rehydrates the display.
    try {
      await _accept(result);
    } catch (_) {
      _stale = true;
    }
    return result;
  });

  Future<int> _accept(GemServerResult result) async {
    await _store.cacheServerBalance(result.balance, ownerId: ownerId);
    _stale = false;
    return result.balance;
  }

  Future<T> _locked<T>(Future<T> Function() run) async {
    if (_busy) throw GemSpendException(GemsCopy.busy);
    _busy = true;
    try {
      return await run();
    } finally {
      _busy = false;
    }
  }

  @Deprecated(
    'Local credits are forbidden; use a purpose-specific server command.',
  )
  Future<int> earn({
    required int amount,
    required String reason,
    String? operationId,
  }) => Future<int>.error(const GemSpendException('server_authority_required'));

  @Deprecated(
    'Local debits are forbidden; use a purpose-specific server command.',
  )
  Future<int> spend({
    required int amount,
    required String reason,
    String? operationId,
  }) => Future<int>.error(const GemSpendException('server_authority_required'));
}
