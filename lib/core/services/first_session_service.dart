/// RC-012 — Detects whether the user is still in their first session.
library;

import '../domain/repositories/history_repository.dart';

class FirstSessionService {
  FirstSessionService(this._history);

  final HistoryRepository _history;

  Future<bool> isFirstSession() async {
    final readings = await _history.getReadings();
    return readings.isEmpty;
  }
}
