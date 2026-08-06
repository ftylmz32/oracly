/// SPRINT-004 — Local privacy preferences for personal insights.
library;

import '../../../core/data/datasources/local_storage.dart';

class PersonalInsightsPreferences {
  const PersonalInsightsPreferences({
    this.hiddenIds = const {},
    this.deletedIds = const {},
  });

  final Set<String> hiddenIds;
  final Set<String> deletedIds;

  PersonalInsightsPreferences copyWith({
    Set<String>? hiddenIds,
    Set<String>? deletedIds,
  }) {
    return PersonalInsightsPreferences(
      hiddenIds: hiddenIds ?? this.hiddenIds,
      deletedIds: deletedIds ?? this.deletedIds,
    );
  }
}

class PersonalInsightsPreferencesRepository {
  PersonalInsightsPreferencesRepository(this._storage);

  static const _hiddenKey = 'personal_insights_hidden';
  static const _deletedKey = 'personal_insights_deleted';

  final LocalStorage _storage;

  Future<PersonalInsightsPreferences> load() async {
    return PersonalInsightsPreferences(
      hiddenIds: _readSet(_hiddenKey),
      deletedIds: _readSet(_deletedKey),
    );
  }

  Future<void> hide(String insightId) async {
    final prefs = await load();
    final next = {...prefs.hiddenIds, insightId};
    await _storage.setStringList(_hiddenKey, next.toList());
  }

  Future<void> unhide(String insightId) async {
    final prefs = await load();
    final next = {...prefs.hiddenIds}..remove(insightId);
    await _storage.setStringList(_hiddenKey, next.toList());
  }

  Future<void> delete(String insightId) async {
    final prefs = await load();
    final hidden = {...prefs.hiddenIds}..remove(insightId);
    final deleted = {...prefs.deletedIds, insightId};
    await _storage.setStringList(_hiddenKey, hidden.toList());
    await _storage.setStringList(_deletedKey, deleted.toList());
  }

  Future<void> clearHidden() async {
    await _storage.remove(_hiddenKey);
  }

  Set<String> _readSet(String key) {
    final list = _storage.getStringList(key);
    if (list == null || list.isEmpty) return {};
    return list.toSet();
  }
}
