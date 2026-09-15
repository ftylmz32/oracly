/// Minimum acceleration client. No buttons, no local gem arithmetic.
library;

// ignore_for_file: prefer_initializing_formals

import '../models/reading_acceleration.dart';
import 'reading_operation_gateway.dart';

class ReadingAccelerationClient {
  ReadingAccelerationClient({
    required this._send,
    Future<void> Function(int balance)? onAuthoritativeBalance,
  }) : _onAuthoritativeBalance = onAuthoritativeBalance;

  final ReadingOperationSender _send;
  final Future<void> Function(int balance)? _onAuthoritativeBalance;

  Future<ReadingAccelerationView> accelerate({
    required String operationId,
    required String idempotencyKey,

    /// Echo of the priceToken the user's quote showed -- never the price
    /// itself, only proof of which one the user agreed to. Omit if no
    /// quote was fetched; the server then just charges its current cost.
    String? expectedPriceToken,
  }) async {
    final wire =
        await _send('POST', '/v1/reading-operations/$operationId/accelerate', {
          'idempotencyKey': idempotencyKey,
          if (expectedPriceToken != null)
            'expectedPriceToken': expectedPriceToken,
        });
    if (wire == null) {
      return const ReadingAccelerationView(
        outcome: ReadingAccelerationOutcome.reconcile,
        balance: null,
        canonicalCost: 0,
        idempotent: false,
      );
    }
    final code = wire.json?['error'];
    if (code is Map && code['code'] == 'insufficient_gems') {
      final current = await fetchBalance();
      return ReadingAccelerationView(
        outcome: ReadingAccelerationOutcome.insufficientGems,
        balance: current?.balance,
        canonicalCost: 0,
        idempotent: false,
      );
    }
    if (wire.statusCode < 200 || wire.statusCode >= 300) {
      return const ReadingAccelerationView(
        outcome: ReadingAccelerationOutcome.reconcile,
        balance: null,
        canonicalCost: 0,
        idempotent: false,
      );
    }
    final data = wire.json?['data'];
    if (data is! Map) {
      return const ReadingAccelerationView(
        outcome: ReadingAccelerationOutcome.reconcile,
        balance: null,
        canonicalCost: 0,
        idempotent: false,
      );
    }
    if (data['balance'] is! int) {
      return const ReadingAccelerationView(
        outcome: ReadingAccelerationOutcome.reconcile,
        balance: null,
        canonicalCost: 0,
        idempotent: false,
      );
    }
    final balance = data['balance'] as int;
    await _onAuthoritativeBalance?.call(balance);
    return ReadingAccelerationView(
      outcome: _outcome(data['outcome']),
      balance: balance,
      canonicalCost: data['canonicalCost'] is int
          ? data['canonicalCost'] as int
          : 0,
      idempotent: data['idempotent'] == true,
      priceToken: data['priceToken'] is String
          ? data['priceToken'] as String
          : null,
    );
  }

  /// Read-only -- no idempotency key, no body, cannot debit. Safe to call
  /// repeatedly (e.g. every time the waiting screen appears) and safe to
  /// ignore a null/failed result, since it never gates the actual charge.
  Future<ReadingAccelerationQuote?> quoteAcceleration({
    required String operationId,
  }) async {
    final wire = await _send(
      'GET',
      '/v1/reading-operations/$operationId/accelerate',
      null,
    );
    if (wire == null || wire.statusCode < 200 || wire.statusCode >= 300) {
      return null;
    }
    final data = wire.json?['data'];
    if (data is! Map ||
        data['canonicalCost'] is! int ||
        data['balance'] is! int ||
        data['priceToken'] is! String ||
        data['payable'] is! bool) {
      return null;
    }
    return ReadingAccelerationQuote(
      canonicalCost: data['canonicalCost'] as int,
      balance: data['balance'] as int,
      priceToken: data['priceToken'] as String,
      payable: data['payable'] as bool,
    );
  }

  Future<ReadingGemBalance?> fetchBalance() async {
    final wire = await _send('GET', '/v1/gems/balance', null);
    if (wire == null || wire.statusCode < 200 || wire.statusCode >= 300) {
      return null;
    }
    final data = wire.json?['data'];
    if (data is! Map || data['balance'] is! int) return null;
    final balance = data['balance'] as int;
    await _onAuthoritativeBalance?.call(balance);
    return ReadingGemBalance(balance);
  }

  ReadingAccelerationOutcome _outcome(Object? value) {
    return switch (value) {
      'accelerated' => ReadingAccelerationOutcome.accelerated,
      'already_accelerated' => ReadingAccelerationOutcome.alreadyAccelerated,
      'already_ready' => ReadingAccelerationOutcome.alreadyReady,
      'already_eligible' => ReadingAccelerationOutcome.alreadyEligible,
      'price_changed' => ReadingAccelerationOutcome.priceChanged,
      _ => ReadingAccelerationOutcome.reconcile,
    };
  }
}
