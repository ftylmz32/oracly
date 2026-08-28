/// UI-facing gem wallet — one notifier for every screen.
library;

import 'package:flutter/foundation.dart';

import '../copy/gems_copy.dart';
import '../data/gem_display.dart';
import '../models/gem_transaction.dart';
import '../services/gem_wallet_service.dart';

class GemWalletController extends ChangeNotifier {
  GemWalletController(this._service) {
    _balance = _service.balance;
    _history = _service.history;
  }

  final GemWalletService _service;

  int _balance = 0;
  List<GemTransaction> _history = const [];
  bool _busy = false;

  int get balance => _balance;
  String get formatted => GemDisplay.format(_balance);
  List<GemTransaction> get history => _history;
  bool get busy => _busy || _service.busy;

  bool canSpend(int amount) => !_busy && _service.canSpend(amount);

  void reload() {
    _balance = _service.balance;
    _history = _service.history;
    notifyListeners();
  }

  Future<bool> earn({
    required int amount,
    required String reason,
  }) async {
    if (_busy) return false;
    _busy = true;
    notifyListeners();
    try {
      _balance = await _service.earn(amount: amount, reason: reason);
      _history = _service.history;
      return true;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> spend({
    required int amount,
    required String reason,
  }) async {
    if (_busy) return false;
    if (!canSpend(amount)) {
      notifyListeners();
      return false;
    }
    _busy = true;
    notifyListeners();
    try {
      _balance = await _service.spend(amount: amount, reason: reason);
      _history = _service.history;
      return true;
    } on GemSpendException {
      _balance = _service.balance;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  String get insufficientMessage => GemsCopy.insufficient;
}
