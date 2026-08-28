/// Local quality log — capped metadata, never private text.
library;

import 'dart:convert';

import '../data/datasources/local_storage.dart';
import 'quality_loop_privacy.dart';
import 'quality_signal_event.dart';

class QualitySignalStore {
  QualitySignalStore(this._storage);

  static const key = 'or_quality_signals_v1';
  static const maxEvents = 200;

  final LocalStorage _storage;

  List<QualitySignalEvent> all() {
    final raw = _storage.getStringList(key) ?? const [];
    return [for (final row in raw) ..._decode(row)];
  }

  Future<void> add(QualitySignalEvent event) async {
    final json = event.toJson();
    if (!QualityLoopPrivacy.isSafe(json)) return;
    if (QualityLoopPrivacy.trainsFromUserContent) return;
    final next = [event, ...all()].take(maxEvents).toList();
    await _storage.setStringList(
      key,
      [for (final item in next) jsonEncode(item.toJson())],
    );
  }

  static Iterable<QualitySignalEvent> _decode(String row) {
    try {
      final decoded = jsonDecode(row);
      if (decoded is! Map) return const [];
      final json = Map<String, dynamic>.from(decoded);
      if (!QualityLoopPrivacy.isSafe(json)) return const [];
      return [QualitySignalEvent.fromJson(json)];
    } catch (_) {
      return const [];
    }
  }
}
