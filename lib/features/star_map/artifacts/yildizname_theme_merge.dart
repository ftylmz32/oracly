/// Merge Yıldızname history themes with PersonalDiscovery labels (max 3).
library;

import 'yildizname_artifact_memory.dart';

abstract final class YildiznameThemeMerge {
  YildiznameThemeMerge._();

  static const maxThemes = 3;

  /// Prefer Yıldızname history; fill from discovery; case-insensitive dedupe.
  static List<String> mergeLabels({
    required List<YildiznameRecurringTheme> artifactThemes,
    required List<String> personalDiscoveryLabels,
  }) {
    final out = <String>[];
    final seen = <String>{};

    void add(String raw) {
      final label = raw.trim();
      if (label.isEmpty) return;
      final key = label.toLowerCase();
      if (seen.contains(key)) return;
      if (out.length >= maxThemes) return;
      seen.add(key);
      out.add(label);
    }

    final history = List<YildiznameRecurringTheme>.from(artifactThemes)
      ..sort((a, b) {
        final c = b.supportCount.compareTo(a.supportCount);
        if (c != 0) return c;
        final t = b.latestOccurredAt.compareTo(a.latestOccurredAt);
        if (t != 0) return t;
        return a.label.toLowerCase().compareTo(b.label.toLowerCase());
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
