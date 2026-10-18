/// First-encounter curiosities — real theme ids, never a guessed life.
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/data/datasources/local_storage.dart';

abstract final class EncounterInterests {
  EncounterInterests._();

  static const ids = ['love', 'future', 'self', 'work', 'curious'];

  /// Only themes the product already understands. Curiosity adds none.
  static const themeById = {
    'love': 'love',
    'future': 'change',
    'self': 'inward',
    'work': 'career',
  };

  static List<String> themeLabels(List<String> ids) {
    return [
      for (final id in ids)
        if (themeById[id] != null) themeById[id]!,
    ];
  }

  /// Observed history wins. Chosen themes fill only an empty profile.
  static List<String> forReading({
    required List<String> chosen,
    required List<String> observed,
  }) {
    if (observed.isNotEmpty) return const [];
    return chosen;
  }
}

class EncounterInterestStore {
  const EncounterInterestStore(this._storage);

  final LocalStorage _storage;

  static const key = 'encounter_interest_ids';

  List<String> load() => decode(_storage.getString(key));

  Future<void> save(List<String> ids) async {
    final clean = [
      for (final id in ids)
        if (EncounterInterests.ids.contains(id)) id,
    ];
    await _storage.setString(key, jsonEncode(clean));
  }

  static List<String> decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final json = jsonDecode(raw);
      if (json is! List) return const [];
      return [
        for (final item in json)
          if (item is String && EncounterInterests.ids.contains(item)) item,
      ];
    } catch (_) {
      return const [];
    }
  }
}

final encounterThemesProvider = Provider<List<String>>((ref) {
  final stored = EncounterInterestStore(ref.watch(localStorageProvider)).load();
  return EncounterInterests.themeLabels(stored);
});
