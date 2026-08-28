/// Persists the user's selected zodiac sign locally.
library;

import '../../../core/data/datasources/local_storage.dart';

class AstrologyPreferencesStore {
  AstrologyPreferencesStore(this._storage);

  static const signKey = 'astrology_selected_sign';

  final LocalStorage _storage;

  String? get selectedSignId {
    final id = _storage.getString(signKey)?.trim();
    if (id == null || id.isEmpty) return null;
    return id;
  }

  Future<void> setSelectedSignId(String id) {
    return _storage.setString(signKey, id);
  }
}
