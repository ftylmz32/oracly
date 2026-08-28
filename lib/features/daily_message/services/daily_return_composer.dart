/// One ritual sentence and one free next step for the calendar day.
library;

import '../../premium/models/personalization_models.dart';
import '../../../core/feature_flags/feature_flag_rollback.dart';
import '../../../core/feature_flags/feature_flag_surface.dart';
import '../data/daily_message_catalogue.dart';
import '../data/daily_ritual_theme_lines.dart';
import '../models/daily_return_action.dart';
import 'daily_ritual_picker.dart';
import 'daily_return_evidence.dart';

class DailyRitualCompose {
  const DailyRitualCompose({
    required this.text,
    this.theme,
    required this.action,
  });

  final String text;
  final String? theme;
  final DailyReturnAction action;
}

abstract final class DailyReturnComposer {
  DailyReturnComposer._();

  static DailyRitualCompose compose({
    required DateTime day,
    String salt = '',
    List<String> themes = const [],
    String? insightTheme,
    String? insightExplanation,
    String? previousTheme,
    String? previousText,
    List<String> recentTexts = const [],
    DailyReturnAction? previousAction,
    AiPersonality? personality,
    bool hasDiscoveries = false,
  }) {
    final useThemeEngine = FeatureFlagRollback.useExperimental(
      FeatureFlagSurface.dailyMessage,
    );
    final theme = useThemeEngine
        ? _theme(
            insightTheme: insightTheme,
            themes: themes,
            previousTheme: previousTheme,
          )
        : null;
    final recent = [
      ?previousText,
      ...recentTexts,
    ];
    final seed =
        '${day.year}-${day.month}-${day.day}-$salt-${theme ?? ''}-${personality?.name ?? ''}';
    final evidence = theme == null
        ? const <String>[]
        : DailyReturnEvidence.lines(
            day: day,
            theme: theme,
            explanation: insightExplanation,
            hasDiscoveries: hasDiscoveries,
          );
    final pool = theme == null
        ? DailyMessageCatalogue.dateAware(day)
        : evidence.isNotEmpty
            ? evidence
            : DailyRitualThemeLines.forTheme(
                theme,
                hasDiscoveries: hasDiscoveries,
              );
    final text = DailyRitualPicker.line(
      pool: pool,
      seed: seed,
      recent: recent,
      voice: personality,
    );
    return DailyRitualCompose(
      text: text,
      theme: theme,
      action: action(
        day: day,
        hasTheme: theme != null,
        previous: previousAction,
      ),
    );
  }

  static DailyReturnAction action({
    required DateTime day,
    required bool hasTheme,
    DailyReturnAction? previous,
  }) {
    final pool = [
      DailyReturnAction.talkToOr,
      if (hasTheme) DailyReturnAction.exploreTheme,
    ];
    if (pool.length == 1) return pool.first;
    if (previous == DailyReturnAction.talkToOr) {
      return DailyReturnAction.exploreTheme;
    }
    if (previous == DailyReturnAction.exploreTheme) {
      return DailyReturnAction.talkToOr;
    }
    return day.day.isEven
        ? DailyReturnAction.exploreTheme
        : DailyReturnAction.talkToOr;
  }

  static String? _theme({
    required String? insightTheme,
    required List<String> themes,
    required String? previousTheme,
  }) {
    final ordered = <String>[
      if (insightTheme != null && insightTheme.trim().isNotEmpty)
        insightTheme.trim(),
      for (final raw in themes)
        if (raw.trim().isNotEmpty) raw.trim(),
    ];
    final unique = <String>[];
    for (final item in ordered) {
      if (!unique.contains(item)) unique.add(item);
    }
    if (unique.isEmpty) return null;
    if (previousTheme != null && previousTheme.isNotEmpty) {
      for (final item in unique) {
        if (item != previousTheme) return item;
      }
    }
    return unique.first;
  }
}
