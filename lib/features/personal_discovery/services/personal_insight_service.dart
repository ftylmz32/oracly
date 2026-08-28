/// Builds structured personal insights from real profile evidence only.
library;

import '../models/cross_discovery_insight.dart';
import '../models/personal_discovery_profile.dart';
import '../models/personal_insight.dart';
import '../models/surfaced_theme_record.dart';
import 'anti_repetition_engine.dart';

abstract final class PersonalInsightService {
  PersonalInsightService._();

  static List<PersonalInsight> fromProfile(
    PersonalDiscoveryProfile profile, {
    DateTime? day,
    List<SurfacedThemeRecord> recent = const [],
    String? surface,
    bool crossModalOnly = true,
  }) {
    final clock = day ?? DateTime.now();
    final pool = profile.crossInsights.where((i) {
      if (!i.isRecurring) return false;
      if (crossModalOnly && !i.isCrossModal) return false;
      return true;
    }).toList();
    final labels = pool.map((i) => i.theme).toList();
    final selected = AntiRepetitionEngine.select(
      candidates: labels,
      recent: recent,
      now: clock,
      surface: surface,
    );
    return [
      for (final theme in selected)
        _map(pool.firstWhere((i) => i.theme == theme)),
    ].take(3).toList(growable: false);
  }

  static PersonalInsight? primary(
    PersonalDiscoveryProfile profile, {
    DateTime? day,
    List<SurfacedThemeRecord> recent = const [],
    String? surface,
  }) {
    final list = fromProfile(
      profile,
      day: day,
      recent: recent,
      surface: surface,
    );
    return list.isEmpty ? null : list.first;
  }

  static PersonalInsight _map(CrossDiscoveryInsight insight) {
    final window = switch (insight.recencyBand) {
      'recent' => 30,
      'aging' => 90,
      _ => 180,
    };
    return PersonalInsight(
      theme: insight.theme,
      sourceCount: insight.sourceCount,
      confidence: insight.confidence,
      recency: insight.recencyBand,
      explanation:
          'Son $window günde ${insight.discoveryCount} keşfinde ve '
          '${insight.sourceCount} farklı alanda yeniden karşına çıkmış.',
    );
  }
}
