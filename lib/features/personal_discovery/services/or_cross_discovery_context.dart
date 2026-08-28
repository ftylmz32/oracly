/// Compact OR context from real chambers — never a history dump.
library;

import '../../../core/l10n/l10n.dart';
import '../copy/personal_theme_copy.dart';
import '../data/discovery_theme_lexicon.dart';
import '../models/cross_discovery_insight.dart';
import '../models/discovery_theme.dart';
import '../models/personal_discovery_profile.dart';
import 'discovery_or_context.dart';
import 'or_cross_discovery_chambers.dart';

/// Tarot · Coffee · Astrology · Yıldızname · Palm · Daily Message.
abstract final class OrCrossDiscoveryContext {
  OrCrossDiscoveryContext._();

  static const maxThemes = 2;
  static const maxChars = 220;
  static const minRepeats = 2;

  /// Relevant OBSERVATION hint for OR. Null when nothing real matches.
  static String? forMessage(
    PersonalDiscoveryProfile profile,
    String userMessage,
  ) {
    final msg = userMessage.trim().toLowerCase();
    if (msg.isEmpty) return null;
    final picks = _picks(profile, msg);
    if (picks.isEmpty) return null;
    final themes = [for (final p in picks) p.theme];
    final cross = picks.any((p) => p.sources.length >= 2);
    final body = cross
        ? PersonalThemeCopy.crossModal(themes)
        : PersonalThemeCopy.recurring(themes);
    final areas = _areaBit(picks.first);
    return _cap(
      [body, ?areas, DiscoveryOrContext.instruction].join(' '),
    );
  }

  static List<_Pick> _picks(PersonalDiscoveryProfile profile, String msg) {
    final out = <_Pick>[
      for (final insight in profile.crossInsights) ?_fromInsight(insight, msg),
    ];
    out.sort((a, b) {
      final cross = b.sources.length.compareTo(a.sources.length);
      return cross != 0 ? cross : b.score.compareTo(a.score);
    });
    final seen = <String>{};
    final limited = <_Pick>[];
    for (final p in out) {
      if (!seen.add(p.theme.toLowerCase())) continue;
      limited.add(p);
      if (limited.length >= maxThemes) break;
    }
    return limited;
  }

  static _Pick? _fromInsight(CrossDiscoveryInsight insight, String msg) {
    final sources = [
      for (final s in insight.sources)
        if (OrCrossDiscoveryChambers.ids.contains(s)) s,
    ];
    if (sources.isEmpty) return null;
    if (insight.discoveryCount < minRepeats && sources.length < 2) return null;
    final hit = _themeRelevant(insight.theme, msg) ||
        sources.any((s) => OrCrossDiscoveryChambers.mentioned(s, msg));
    if (!hit) return null;
    return _Pick(
      theme: insight.theme,
      sources: sources,
      score: insight.discoveryCount + (sources.length * 3),
    );
  }

  static String? _areaBit(_Pick pick) {
    if (pick.sources.length < 2) return null;
    final labels = [
      for (final s in pick.sources.take(3)) OrCrossDiscoveryChambers.label(s),
    ].where((l) => l.isNotEmpty).toList();
    if (labels.length < 2) return null;
    return OraclyL10n.t('or.ctx.areas').replaceAll('{areas}', labels.join(', '));
  }

  static bool _themeRelevant(String themeLabel, String message) {
    final theme = DiscoveryTheme.resolve(themeLabel);
    if (theme == null) return message.contains(themeLabel.toLowerCase());
    final tokens = <String>[
      theme.label,
      theme.localized,
      ...?DiscoveryThemeLexicon.map[theme],
      if (theme == DiscoveryTheme.career) 'iş',
    ];
    return tokens.any((t) => message.contains(t.toLowerCase()));
  }

  static String _cap(String text) {
    final t = text.trim();
    if (t.length <= maxChars) return t;
    final cut = t.substring(0, maxChars);
    final space = cut.lastIndexOf(' ');
    return space > 140 ? cut.substring(0, space) : cut;
  }
}

class _Pick {
  const _Pick({
    required this.theme,
    required this.sources,
    required this.score,
  });
  final String theme;
  final List<String> sources;
  final int score;
}
