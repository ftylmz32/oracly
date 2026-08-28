/// Compares two real discoveries — observational synthesis only.
library;

import '../../../features/personal_discovery/models/discovery_theme.dart';
import '../../../features/personal_discovery/services/personal_theme_extractor.dart';
import '../copy/discovery_comparison_copy.dart';
import '../models/discovery_comparison_kind.dart';
import '../models/discovery_comparison_result.dart';
import '../models/discovery_comparison_snapshot.dart';

enum _ComparisonAccent { obstacle, direction, none }

abstract final class DiscoveryComparisonEngine {
  DiscoveryComparisonEngine._();

  static DiscoveryComparisonResult? compare({
    required DiscoveryComparisonKind kind,
    required DiscoveryComparisonSnapshot earlier,
    required DiscoveryComparisonSnapshot later,
  }) {
    if (earlier.id == later.id) return null;
    if (earlier.text.trim().isEmpty || later.text.trim().isEmpty) return null;

    final earlierThemes = PersonalThemeExtractor.themesIn(earlier.text);
    final laterThemes = PersonalThemeExtractor.themesIn(later.text);
    if (earlierThemes.isEmpty && laterThemes.isEmpty) return null;

    final earlierTheme = _dominantTheme(earlierThemes);
    final laterTheme = _dominantTheme(laterThemes);
    final synthesis = _synthesis(
      kind: kind,
      earlierThemes: earlierThemes,
      laterThemes: laterThemes,
      earlierTheme: earlierTheme,
      laterTheme: laterTheme,
    );
    if (synthesis == null) return null;

    return DiscoveryComparisonResult(
      kind: kind,
      earlier: earlier,
      later: later,
      synthesis: synthesis,
    );
  }

  static String? _synthesis({
    required DiscoveryComparisonKind kind,
    required Set<DiscoveryTheme> earlierThemes,
    required Set<DiscoveryTheme> laterThemes,
    required DiscoveryTheme? earlierTheme,
    required DiscoveryTheme? laterTheme,
  }) {
    if (kind == DiscoveryComparisonKind.tarot &&
        _accent(earlierThemes) == _ComparisonAccent.obstacle &&
        _accent(laterThemes) == _ComparisonAccent.direction) {
      return DiscoveryComparisonCopy.obstacleToDirectionTarot;
    }

    if (earlierTheme != null &&
        laterTheme != null &&
        earlierTheme == laterTheme) {
      return DiscoveryComparisonCopy.stableTheme(
        DiscoveryComparisonCopy.themeLabel(earlierTheme),
      );
    }

    if (earlierTheme != null && laterTheme != null) {
      return DiscoveryComparisonCopy.shift(
        kind,
        DiscoveryComparisonCopy.themeLabel(earlierTheme),
        DiscoveryComparisonCopy.themeLabel(laterTheme),
      );
    }

    return null;
  }

  static DiscoveryTheme? _dominantTheme(Set<DiscoveryTheme> themes) {
    if (themes.isEmpty) return null;
    const priority = [
      DiscoveryTheme.decision,
      DiscoveryTheme.redirection,
      DiscoveryTheme.change,
      DiscoveryTheme.uncertainty,
      DiscoveryTheme.indecision,
      DiscoveryTheme.boundaries,
      DiscoveryTheme.courage,
      DiscoveryTheme.career,
      DiscoveryTheme.love,
      DiscoveryTheme.relationship,
    ];
    for (final theme in priority) {
      if (themes.contains(theme)) return theme;
    }
    return themes.first;
  }

  static _ComparisonAccent _accent(Set<DiscoveryTheme> themes) {
    if (themes.any(
      (t) =>
          t == DiscoveryTheme.boundaries ||
          t == DiscoveryTheme.uncertainty ||
          t == DiscoveryTheme.indecision,
    )) {
      return _ComparisonAccent.obstacle;
    }
    if (themes.any(
      (t) =>
          t == DiscoveryTheme.redirection ||
          t == DiscoveryTheme.decision ||
          t == DiscoveryTheme.courage,
    )) {
      return _ComparisonAccent.direction;
    }
    return _ComparisonAccent.none;
  }
}
