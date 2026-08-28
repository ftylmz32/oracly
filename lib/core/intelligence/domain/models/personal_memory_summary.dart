/// Compact personal memory — observations only, never raw history.
library;

import 'memory_theme_stat.dart';

class PersonalMemorySummary {
  const PersonalMemorySummary({
    this.preferredName,
    this.orStyle,
    this.sunSign,
    this.themes = const [],
    this.recentDiscoveries = const [],
    this.preferences = const [],
    this.recentTopics = const [],
    this.latestMeaningfulDiscovery,
    this.fingerprint = '',
    this.updatedAt,
  });

  static const empty = PersonalMemorySummary();
  static const schemaVersion = 1;

  final String? preferredName;
  final String? orStyle;
  final String? sunSign;
  final List<MemoryThemeStat> themes;
  final List<String> recentDiscoveries;
  final List<String> preferences;
  final List<String> recentTopics;
  final String? latestMeaningfulDiscovery;
  final String fingerprint;
  final DateTime? updatedAt;

  bool get isEmpty =>
      (preferredName == null || preferredName!.isEmpty) &&
      (orStyle == null || orStyle!.isEmpty) &&
      (sunSign == null || sunSign!.isEmpty) &&
      themes.isEmpty &&
      recentDiscoveries.isEmpty &&
      preferences.isEmpty &&
      recentTopics.isEmpty &&
      (latestMeaningfulDiscovery == null ||
          latestMeaningfulDiscovery!.isEmpty);

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        if (preferredName != null) 'preferredName': preferredName,
        if (orStyle != null) 'orStyle': orStyle,
        if (sunSign != null) 'sunSign': sunSign,
        'themes': themes.map((t) => t.toJson()).toList(),
        'recentDiscoveries': recentDiscoveries,
        'preferences': preferences,
        'recentTopics': recentTopics,
        if (latestMeaningfulDiscovery != null)
          'latestMeaningfulDiscovery': latestMeaningfulDiscovery,
        'fingerprint': fingerprint,
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  factory PersonalMemorySummary.fromJson(Map<String, dynamic> json) {
    final themesRaw = json['themes'] as List<dynamic>? ?? const [];
    return PersonalMemorySummary(
      preferredName: _clip(json['preferredName'] as String?, 40),
      orStyle: _clip(json['orStyle'] as String?, 24),
      sunSign: _clip(json['sunSign'] as String?, 24),
      themes: [
        for (final row in themesRaw)
          if (row is Map<String, dynamic>) MemoryThemeStat.fromJson(row),
      ],
      recentDiscoveries: _list(json['recentDiscoveries'], 8, 24),
      preferences: _list(json['preferences'], 8, 32),
      recentTopics: _list(json['recentTopics'], 5, 32),
      latestMeaningfulDiscovery:
          _clip(json['latestMeaningfulDiscovery'] as String?, 48),
      fingerprint: (json['fingerprint'] as String? ?? '').trim(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }

  static String? _clip(String? raw, int max) {
    final text = raw?.trim();
    if (text == null || text.isEmpty) return null;
    return text.length <= max ? text : text.substring(0, max);
  }

  static List<String> _list(dynamic raw, int maxItems, int maxLen) {
    if (raw is! List) return const [];
    final out = <String>[];
    for (final item in raw) {
      if (out.length >= maxItems) break;
      final text = item?.toString().trim() ?? '';
      if (text.isEmpty) continue;
      out.add(text.length <= maxLen ? text : text.substring(0, maxLen));
    }
    return List.unmodifiable(out);
  }
}
