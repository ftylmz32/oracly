/// OR cites only compact, real, recent themes — never identity claims.
library;

import '../../../core/l10n/l10n.dart';
import '../../../core/personality/or_personality.dart';
import '../copy/personal_theme_copy.dart';
import '../models/personal_discovery_profile.dart';
import 'or_cross_discovery_context.dart';

abstract final class DiscoveryOrContext {
  DiscoveryOrContext._();

  static const maxThemes = 3;

  static String get instruction => OraclyL10n.t('or.ctx.instruction');

  static String? line(List<String> themes) {
    final clean = themes.where((t) => t.trim().isNotEmpty).toList();
    if (clean.isEmpty) return null;
    return '${PersonalThemeCopy.recurring(clean)} $instruction';
  }

  static List<String> themeLabels(
    PersonalDiscoveryProfile profile, {
    int max = maxThemes,
  }) {
    final themes = <String>[];
    void take(Iterable<String> source) {
      for (final raw in source) {
        if (themes.length >= max) return;
        final theme = raw.trim();
        if (theme.isEmpty || themes.contains(theme)) continue;
        themes.add(theme);
      }
    }

    take(profile.observedRecurringLabels);
    take(profile.recentCrossInsights.map((i) => i.theme));
    if (themes.length < max) take(profile.recurringThemes);
    return List.unmodifiable(themes);
  }

  static String? compactForMessage(
    PersonalDiscoveryProfile profile,
    String userMessage,
  ) =>
      OrCrossDiscoveryContext.forMessage(profile, userMessage);

  static String? compact(PersonalDiscoveryProfile profile, {int max = 3}) {
    final themes = themeLabels(profile, max: max);
    if (themes.isEmpty) return null;
    final head = OraclyL10n.t('or.ctx.observed').replaceAll(
      '{themes}',
      themes.join(', '),
    );
    final style = profile.preferredOrStyle;
    if (style == null) return '$head $instruction';
    final tone = OraclyL10n.t('or.ctx.style').replaceAll(
      '{style}',
      OrPersonality.label(style),
    );
    return '$head $tone $instruction';
  }

  static String mergeHint(String? base, List<String> themes) {
    final hint = (base ?? '').trim();
    final extra = line(themes);
    if (extra == null) return hint;
    if (hint.isEmpty) return extra;
    return '$hint $extra';
  }

  static String mergeCompact(String? base, PersonalDiscoveryProfile profile) {
    final hint = (base ?? '').trim();
    final extra = compact(profile);
    if (extra == null) return hint;
    if (hint.isEmpty) return extra;
    return '$hint $extra';
  }
}
