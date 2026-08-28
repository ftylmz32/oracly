/// Overlays real sun-sign + observed themes. Never invents natal data.
library;

import '../../personal_discovery/copy/personal_theme_copy.dart';
import '../../personal_discovery/models/discovery_theme.dart';
import '../../personal_discovery/models/personal_discovery_profile.dart';
import '../models/astrology_daily_reading.dart';
import 'astrology_fortune_story.dart';

abstract final class AstrologyPersonalization {
  AstrologyPersonalization._();

  static AstrologyDailyReading overlay({
    required AstrologyDailyReading base,
    required String signName,
    PersonalDiscoveryProfile? profile,
    required DateTime day,
    List<String> selectedThemes = const [],
  }) {
    final themes = selectedThemes.isNotEmpty
        ? selectedThemes
        : (profile?.observedRecurringLabels ?? const <String>[]);
    final seed = day.year * 19 + day.month * 31 + day.day + signName.length;
    final focus = themes.isEmpty
        ? ''
        : (DiscoveryTheme.resolve(themes[day.day % themes.length])?.localized ??
            themes[day.day % themes.length]);
    final loveLife = _firstOf(themes, _love) ?? '';
    final careerLife = _firstOf(themes, _career) ?? '';
    return base.copyWith(
      overall: AstrologyFortuneStory.overall(
        sign: signName,
        catalog: base.overall,
        feel: base.emotion,
        watch: base.caution,
        life: focus,
        domain: '',
        seed: seed,
      ),
      love: loveLife.isEmpty
          ? ''
          : AstrologyFortuneStory.lane(
              sign: signName,
              catalog: base.love,
              life: loveLife,
              seed: seed + 1,
            ),
      career: careerLife.isEmpty
          ? ''
          : AstrologyFortuneStory.lane(
              sign: signName,
              catalog: base.career,
              life: careerLife,
              seed: seed + 2,
            ),
      emotion: AstrologyFortuneStory.lane(
        sign: signName,
        catalog: base.emotion,
        life: focus,
        seed: seed + 4,
      ),
      money: '',
      advice: AstrologyFortuneStory.lane(
        sign: signName,
        catalog: base.advice,
        life: focus,
        seed: seed + 6,
      ),
      energy: AstrologyFortuneStory.lane(
        sign: signName,
        catalog: base.energy,
        life: focus,
        seed: seed + 7,
      ),
      opportunity: AstrologyFortuneStory.lane(
        sign: signName,
        catalog: base.opportunity,
        life: focus,
        seed: seed + 8,
      ),
      caution: AstrologyFortuneStory.lane(
        sign: signName,
        catalog: base.caution,
        life: focus,
        seed: seed + 9,
      ),
      innerTheme: themes.isEmpty
          ? PersonalThemeCopy.insufficient
          : AstrologyFortuneStory.inner(
              observed: PersonalThemeCopy.crossModal(themes),
              domain: '',
              seed: seed,
            ),
    );
  }

  static bool hasRelationshipTheme(List<String> themes) =>
      _firstOf(themes, _love) != null;

  static bool hasDirectionTheme(List<String> themes) =>
      _firstOf(themes, _career) != null;

  static const _love = {
    DiscoveryTheme.love,
    DiscoveryTheme.relationship,
    DiscoveryTheme.communication,
  };

  static const _career = {
    DiscoveryTheme.career,
    DiscoveryTheme.money,
    DiscoveryTheme.decision,
    DiscoveryTheme.change,
    DiscoveryTheme.redirection,
  };

  static String? _firstOf(List<String> themes, Set<DiscoveryTheme> keys) {
    for (final theme in themes) {
      final id = DiscoveryTheme.resolve(theme);
      if (id != null && keys.contains(id)) return id.localized;
    }
    return null;
  }
}
