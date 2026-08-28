/// Honest aggregate of existing ORACLY records. Never invented.
library;

import '../../birth_chart/models/zodiac_sign_id.dart';
import '../../premium/models/personalization_models.dart';
import 'cross_discovery_insight.dart';
import 'discovery_observation.dart';
import 'discovery_source_activity.dart';
import 'discovery_theme_signal.dart';
import 'discovery_theme_strength.dart';

class PersonalDiscoveryProfile {
  const PersonalDiscoveryProfile({
    this.birthDate,
    this.birthPlace,
    this.zodiacSign,
    this.preferredOrStyle,
    this.tarotThemes = const [],
    this.dreamThemes = const [],
    this.coffeeThemes = const [],
    this.reflectionThemes = const [],
    this.palmThemes = const [],
    this.themeSignals = const [],
    this.observations = const [],
    this.crossInsights = const [],
    this.soulmateGenerations = 0,
    this.lastUpdated,
    this.tarotCount = 0,
    this.dreamCount = 0,
    this.coffeeCount = 0,
    this.reflectionCount = 0,
    this.palmCount = 0,
    this.astrologyCount = 0,
    this.dailyMessageCount = 0,
    this.starMapCount = 0,
    this.sourceActivity = const [],
  });

  final DateTime? birthDate;
  final String? birthPlace;
  final ZodiacSignId? zodiacSign;
  final AiPersonality? preferredOrStyle;
  final List<String> tarotThemes;
  final List<String> dreamThemes;
  final List<String> coffeeThemes;
  final List<String> reflectionThemes;
  final List<String> palmThemes;
  final List<DiscoveryThemeSignal> themeSignals;
  final List<DiscoveryObservation> observations;
  final List<CrossDiscoveryInsight> crossInsights;
  final int soulmateGenerations;
  final DateTime? lastUpdated;
  final int tarotCount;
  final int dreamCount;
  final int coffeeCount;
  final int reflectionCount;
  final int palmCount;
  final int astrologyCount;
  final int dailyMessageCount;
  final int starMapCount;
  final List<DiscoverySourceActivity> sourceActivity;

  bool get hasBirth => birthDate != null;
  bool get hasHistory =>
      tarotCount +
          dreamCount +
          coffeeCount +
          reflectionCount +
          palmCount +
          astrologyCount +
          dailyMessageCount +
          starMapCount >
      0;

  List<String> get recurringThemes => crossInsights
      .where((s) => s.isRecurring)
      .map((s) => s.theme)
      .take(3)
      .toList(growable: false);

  /// Recurring labels from history only — never invented natal data.
  List<String> get observedRecurringLabels {
    final seen = <String>{};
    final out = <String>[];
    void add(String raw) {
      final text = raw.trim();
      if (text.isEmpty || !seen.add(text.toLowerCase())) return;
      out.add(text);
    }

    for (final theme in recurringThemes) {
      add(theme);
    }
    for (final signal in themeSignals) {
      if (signal.isRecurring) add(signal.label);
    }
    return List<String>.unmodifiable(out);
  }

  List<String> get crossModalThemes => crossInsights
      .where((s) => s.isRecurring && s.isCrossModal)
      .map((s) => s.theme)
      .take(3)
      .toList(growable: false);

  /// App-wide personalization — cross-modal, recency-sorted.
  List<String> get personalizationThemes => crossModalThemes;

  List<DiscoveryThemeSignal> get strongThemes => themeSignals
      .where((s) => s.strength == DiscoveryThemeStrength.strong)
      .toList(growable: false);

  List<CrossDiscoveryInsight> get recentCrossInsights => crossInsights
      .where((s) => s.isRecurring && s.isCrossModal)
      .toList(growable: false);

  static const empty = PersonalDiscoveryProfile();
}
