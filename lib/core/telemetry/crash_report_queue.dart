/// Bounded offline queue for safe crash metadata only.
library;

import 'dart:convert';

import '../data/datasources/local_storage.dart';
import 'crash_report.dart';

class CrashReportQueue {
  CrashReportQueue(this._storage);

  final LocalStorage _storage;

  static const _key = 'crash_telemetry_queue';
  static const maxItems = 8;

  List<CrashReport> peek() {
    final raw = _storage.getStringList(_key);
    if (raw == null || raw.isEmpty) return const [];
    final out = <CrashReport>[];
    for (final line in raw) {
      try {
        final map = jsonDecode(line) as Map<String, dynamic>;
        out.add(CrashReport.fromQueueJson(map));
      } catch (_) {}
    }
    return out;
  }

  Future<void> enqueue(CrashReport report) async {
    final existing = peek();
    final next = [...existing, report];
    final trimmed = next.length <= maxItems
        ? next
        : next.sublist(next.length - maxItems);
    await _storage.setStringList(
      _key,
      trimmed.map((r) => jsonEncode(r.toQueueJson())).toList(growable: false),
    );
  }

  Future<void> replaceAll(List<CrashReport> reports) async {
    if (reports.isEmpty) {
      await _storage.remove(_key);
      return;
    }
    final trimmed = reports.length <= maxItems
        ? reports
        : reports.sublist(reports.length - maxItems);
    await _storage.setStringList(
      _key,
      trimmed.map((r) => jsonEncode(r.toQueueJson())).toList(growable: false),
    );
  }

  Future<void> clear() => _storage.remove(_key);
}
