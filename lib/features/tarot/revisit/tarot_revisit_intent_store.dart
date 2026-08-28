/// One-shot revisit intent between entry choice and reading AI.
library;

import 'dart:convert';

import '../../../core/data/datasources/local_storage.dart';
import 'tarot_revisit_intent.dart';
import 'tarot_revisit_mode.dart';

class TarotRevisitIntentStore {
  TarotRevisitIntentStore(this._storage);

  static const key = 'tarot_revisit_intent_v1';

  final LocalStorage _storage;

  TarotRevisitIntent? peek() {
    final raw = _storage.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final mode = TarotRevisitMode.values.byName('${json['mode']}');
      final id = '${json['priorReadingId'] ?? ''}'.trim();
      final excerpt = '${json['priorExcerpt'] ?? ''}'.trim();
      if (id.isEmpty || excerpt.isEmpty) return null;
      return TarotRevisitIntent(
        priorReadingId: id,
        mode: mode,
        priorExcerpt: excerpt,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> write(TarotRevisitIntent intent) async {
    await _storage.setString(
      key,
      jsonEncode({
        'priorReadingId': intent.priorReadingId,
        'mode': intent.mode.name,
        'priorExcerpt': intent.priorExcerpt,
      }),
    );
  }

  Future<TarotRevisitIntent?> consume() async {
    final value = peek();
    await clear();
    return value;
  }

  Future<void> clear() => _storage.remove(key);
}
