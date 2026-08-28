/// Local quality log — metadata only, capped, never raw content.
library;

import 'dart:convert';

import '../../../core/data/datasources/local_storage.dart';
import '../models/reading_feedback_event.dart';

class ReadingFeedbackStore {
  ReadingFeedbackStore(this._storage);

  static const key = 'or_reading_feedback_v1';
  static const maxEvents = 40;

  final LocalStorage _storage;

  List<ReadingFeedbackEvent> all() {
    final raw = _storage.getStringList(key) ?? const [];
    return [
      for (final row in raw) ..._decode(row),
    ];
  }

  Future<void> add(ReadingFeedbackEvent event) async {
    final next = [event, ...all()].take(maxEvents).toList();
    await _storage.setStringList(
      key,
      [for (final item in next) jsonEncode(item.toJson())],
    );
  }

  static Iterable<ReadingFeedbackEvent> _decode(String row) {
    try {
      final decoded = jsonDecode(row);
      if (decoded is! Map) return const [];
      final json = Map<String, dynamic>.from(decoded);
      if (json.keys.any((key) => !ReadingFeedbackEvent.allowedKeys.contains(key))) {
        return const [];
      }
      return [ReadingFeedbackEvent.fromJson(json)];
    } catch (_) {
      return const [];
    }
  }
}
