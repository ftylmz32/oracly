/// Adds real observed themes to a sun-sign reading. Never invents natal data.
///
/// The sign text is kept whole; a theme only ever adds one complete sentence
/// after it, so personalised copy cannot splice or repeat catalogue lines.
library;

import '../../../core/l10n/l10n.dart';
import '../../personal_discovery/copy/personal_theme_copy.dart';
import '../../personal_discovery/models/discovery_theme.dart';
import '../../personal_discovery/models/personal_discovery_profile.dart';
import '../models/astrology_daily_reading.dart';

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
    if (themes.isEmpty) {
      return base.copyWith(innerTheme: PersonalThemeCopy.insufficient);
    }
    final d = DateTime.utc(day.year, day.month, day.day)
        .difference(DateTime.utc(2000))
        .inDays;
    final focus = _label(themes[day.day % themes.length]);
    final loveLife = _firstOf(themes, _love);
    final careerLife = _firstOf(themes, _career);
    return base.copyWith(
      overall: _join(base.overall, _bridge('astro.bridge.overall', d, focus)),
      love: loveLife == null
          ? base.love
          : _join(base.love, _bridge('astro.bridge.lane', d + 1, loveLife)),
      career: careerLife == null
          ? base.career
          : _join(
              base.career,
              _bridge('astro.bridge.lane', d + 2, careerLife),
            ),
      innerTheme: _join(
        PersonalThemeCopy.crossModal(themes),
        OraclyL10n.t('astro.inner.close.${d % 3}'),
      ),
      lovePersonal: loveLife != null,
      careerPersonal: careerLife != null,
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

  static String _bridge(String family, int seed, String theme) =>
      OraclyL10n.t('$family.${seed % 3}').replaceAll('{theme}', theme);

  static String _join(String a, String b) {
    final first = a.trim();
    final second = b.trim();
    if (first.isEmpty) return second;
    if (second.isEmpty) return first;
    return '$first $second';
  }

  static String _label(String raw) =>
      DiscoveryTheme.resolve(raw)?.localized ?? raw.trim();

  static String? _firstOf(List<String> themes, Set<DiscoveryTheme> keys) {
    for (final theme in themes) {
      final id = DiscoveryTheme.resolve(theme);
      if (id != null && keys.contains(id)) return id.localized;
    }
    return null;
  }
}
