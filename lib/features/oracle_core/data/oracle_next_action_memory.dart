/// Local NextAction surface memory - not a journey database.
library;

import 'dart:convert';

import '../../../core/data/datasources/local_storage.dart';
import '../../personal_discovery/models/discovery_recommended_feature.dart';
import '../../personal_discovery/services/discovery_recommendation_day.dart';
import '../models/oracle_next_action_event.dart';

class OracleNextActionMemory {
  OracleNextActionMemory(this._storage);

  static const key = 'oracle_core_next_action_memory_v1';
  static const maxRecords = 40;
  static const dismissCooldown = Duration(days: 14);

  final LocalStorage _storage;

  List<OracleNextActionEvent> all() {
    final raw = _storage.getStringList(key) ?? const <String>[];
    final items = <OracleNextActionEvent>[];
    for (final row in raw) {
      try {
        final decoded = jsonDecode(row);
        if (decoded is! Map) continue;
        items.add(
          OracleNextActionEvent.fromJson(Map<String, dynamic>.from(decoded)),
        );
      } catch (_) {}
    }
    return items..sort((a, b) => b.at.compareTo(a.at));
  }

  Future<void> record(OracleNextActionEvent entry) async {
    final next = [entry, ...all()].take(maxRecords).toList();
    await _storage.setStringList(
      key,
      next.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  bool shownToday({
    required String theme,
    required DiscoveryRecommendedFeature feature,
    required DateTime now,
  }) {
    final t = theme.trim().toLowerCase();
    final f = feature.name;
    return all().any(
      (e) =>
          e.kind == 'shown' &&
          e.theme.toLowerCase() == t &&
          e.feature == f &&
          DiscoveryRecommendationDay.sameDay(e.at, now),
    );
  }

  bool dismissBlocked({
    required String theme,
    required DiscoveryRecommendedFeature feature,
    required DateTime now,
    Duration cooldown = dismissCooldown,
  }) {
    final t = theme.trim().toLowerCase();
    final f = feature.name;
    for (final e in all()) {
      if (e.kind != 'dismissed') continue;
      if (e.theme.toLowerCase() != t || e.feature != f) continue;
      if (now.difference(e.at) <= cooldown) return true;
    }
    return false;
  }

  bool isBlocked({
    required String theme,
    required DiscoveryRecommendedFeature feature,
    required DateTime now,
  }) =>
      shownToday(theme: theme, feature: feature, now: now) ||
      dismissBlocked(theme: theme, feature: feature, now: now);
}
