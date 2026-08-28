/// Avoids repeating the same surfaced theme when alternatives exist.
library;

import '../data/theme_alternatives.dart';
import '../models/surfaced_theme_record.dart';

abstract final class AntiRepetitionEngine {
  AntiRepetitionEngine._();

  static const coolDown = Duration(days: 2);
  static const maxRecentHits = 1;

  /// Fresh candidates first. Related alternatives of overused themes
  /// come first when they are actually present. Empty ⇒ neutral copy.
  static List<String> select({
    required List<String> candidates,
    required List<SurfacedThemeRecord> recent,
    DateTime? now,
    String? surface,
    Duration coolDown = coolDown,
    int maxRecentHits = maxRecentHits,
  }) {
    final clock = now ?? DateTime.now();
    final clean = candidates.where((t) => t.trim().isNotEmpty).toList();
    if (clean.isEmpty) return const [];

    final fresh = <String>[];
    final overused = <String>[];
    for (final theme in clean) {
      final hits = recent.where((r) {
        if (r.theme != theme) return false;
        if (surface != null && r.surface != surface) return false;
        return clock.difference(r.at) <= coolDown;
      }).length;
      if (hits < maxRecentHits) {
        fresh.add(theme);
      } else {
        overused.add(theme);
      }
    }
    if (fresh.isEmpty) return const [];
    if (overused.isEmpty) return List.unmodifiable(fresh);

    final preferred = <String>[];
    for (final used in overused) {
      for (final alt in ThemeAlternatives.of(used)) {
        if (fresh.contains(alt) && !preferred.contains(alt)) {
          preferred.add(alt);
        }
      }
    }
    final rest = fresh.where((t) => !preferred.contains(t));
    return List.unmodifiable([...preferred, ...rest]);
  }

  static bool isOverused({
    required String theme,
    required List<SurfacedThemeRecord> recent,
    DateTime? now,
    String? surface,
    Duration coolDown = coolDown,
    int maxRecentHits = maxRecentHits,
  }) {
    return !select(
      candidates: [theme],
      recent: recent,
      now: now,
      surface: surface,
      coolDown: coolDown,
      maxRecentHits: maxRecentHits,
    ).contains(theme);
  }
}
