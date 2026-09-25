/// Merge Yıldızname history themes with PersonalDiscovery labels (max 3).
library;

import 'yildizname_artifact_memory.dart';
import 'yildizname_theme_identity.dart';

abstract final class YildiznameThemeMerge {
  YildiznameThemeMerge._();

  static const maxThemes = 3;

  /// Prefer Yıldızname history; fill from discovery; shared label normalize.
  static List<String> mergeLabels({
    required List<YildiznameRecurringTheme> artifactThemes,
    required List<String> personalDiscoveryLabels,
  }) {
    final out = <String>[];
    final seen = <String>{};

    void add(String raw) {
      final n = YildiznameThemeIdentity.normalize(raw);
      if (n.isEmpty) return;
      if (seen.contains(n)) return;
      if (out.length >= maxThemes) return;
      seen.add(n);
      out.add(raw.trim().replaceAll(RegExp(r'\s+'), ' '));
    }

    final history = List<YildiznameRecurringTheme>.from(artifactThemes)
      ..sort((a, b) {
        final c = b.supportCount.compareTo(a.supportCount);
        if (c != 0) return c;
        final t = b.latestOccurredAt.compareTo(a.latestOccurredAt);
        if (t != 0) return t;
        return a.themeKey.compareTo(b.themeKey);
      });
    for (final t in history) {
      add(t.label);
    }
    for (final label in personalDiscoveryLabels) {
      add(label);
    }
    return out;
  }
}
