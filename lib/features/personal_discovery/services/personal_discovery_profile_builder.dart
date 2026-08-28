/// Builds [PersonalDiscoveryProfile] from existing records only.
library;

import '../../../core/history/history_scale_policy.dart';
import '../../birth_chart/models/zodiac_sign_id.dart';
import '../models/cross_discovery_insight.dart';
import '../models/discovery_theme_signal.dart';
import '../models/personal_discovery_profile.dart';
import '../models/personal_discovery_sources.dart';
import 'discovery_source_activity_builder.dart';
import 'personal_discovery_profile_texts.dart';
import 'personal_theme_extractor.dart';

abstract final class PersonalDiscoveryProfileBuilder {
  PersonalDiscoveryProfileBuilder._();

  static PersonalDiscoveryProfile from(
    PersonalDiscoverySources sources, {
    DateTime? now,
  }) {
    final birth = sources.birth;
    final place = birth?.birthPlace.trim();
    final dated = PersonalDiscoveryProfileTexts.dated(sources);
    final observations = PersonalThemeExtractor.observationsFrom(dated);
    final insights = PersonalThemeExtractor.insightsFrom(
      observations,
      now: now,
    );
    return PersonalDiscoveryProfile(
      birthDate: birth?.birthDate,
      birthPlace: (place == null || place.isEmpty) ? null : place,
      zodiacSign:
          birth == null ? null : ZodiacSignId.fromDate(birth.birthDate),
      preferredOrStyle: sources.settings?.aiPersonality,
      tarotThemes: PersonalThemeExtractor.labelsIn(
        HistoryScalePolicy.newestByDate(
          sources.readings,
          (r) => r.createdAt,
        ).map(PersonalDiscoveryProfileTexts.tarot),
      ),
      dreamThemes: PersonalThemeExtractor.labelsIn(
        HistoryScalePolicy.newestByDate(
          sources.dreams,
          (d) => d.updatedAt ?? d.createdAt,
        ).map(PersonalDiscoveryProfileTexts.dream),
      ),
      coffeeThemes: PersonalThemeExtractor.labelsIn(
        HistoryScalePolicy.newestByDate(
          sources.coffee,
          (c) => c.createdAt,
        ).map((c) => c.fullText),
      ),
      reflectionThemes: PersonalThemeExtractor.labelsIn(
        HistoryScalePolicy.newestByDate(
          sources.conversations,
          (c) => c.updatedAt,
        ).map(PersonalDiscoveryProfileTexts.conversation),
      ),
      palmThemes: PersonalThemeExtractor.labelsIn(
        HistoryScalePolicy.newestByDate(
          sources.palm,
          (p) => p.createdAt,
        ).map((p) => '${p.fullText} ${p.themes.join(' ')}'),
      ),
      astrologyCount: sources.astrology.length,
      dailyMessageCount: sources.dailyMessages.length,
      starMapCount: sources.starChart == null ? 0 : 1,
      observations: observations,
      crossInsights: insights,
      themeSignals: [
        for (final i in insights) _toSignal(i),
      ],
      soulmateGenerations:
          sources.soulmateGenerationCount < 0
              ? 0
              : sources.soulmateGenerationCount,
      lastUpdated: PersonalDiscoveryProfileTexts.latest(sources),
      tarotCount: sources.readings.length,
      dreamCount: sources.dreams.length,
      coffeeCount: sources.coffee.length,
      reflectionCount:
          sources.conversations.where((c) => c.messagesJson.isNotEmpty).length,
      palmCount: sources.palm.length,
      sourceActivity: DiscoverySourceActivityBuilder.from(sources, now: now),
    );
  }

  static DiscoveryThemeSignal _toSignal(CrossDiscoveryInsight i) {
    return DiscoveryThemeSignal(
      label: i.theme,
      discoveryCount: i.discoveryCount,
      sources: i.sources,
      strength: i.confidence,
    );
  }
}
