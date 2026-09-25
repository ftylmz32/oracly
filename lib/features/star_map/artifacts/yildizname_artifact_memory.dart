/// Recurring themes from Narrative V1 artifacts only.
library;

import 'yildizname_artifact.dart';
import 'yildizname_artifact_source.dart';
import 'yildizname_narrative_payload.dart';

final class YildiznameRecurringTheme {
  const YildiznameRecurringTheme({
    required this.themeRef,
    required this.label,
    required this.supportCount,
    required this.sourceArtifactIds,
    required this.latestOccurredAt,
  });

  final String themeRef;
  final String label;
  final int supportCount;
  final List<String> sourceArtifactIds;
  final DateTime latestOccurredAt;

  bool get isRecurring => supportCount >= 2;
}

abstract final class YildiznameArtifactMemory {
  YildiznameArtifactMemory._();

  /// Themes that appear in accepted result themeRefs across ≥2 artifacts.
  static List<YildiznameRecurringTheme> recurringThemes(
    Iterable<YildiznameArtifact> artifacts, {
    String? excludeSemanticFingerprint,
    Set<String>? existingIds,
  }) {
    final byTheme = <String, _Acc>{};
    for (final a in artifacts) {
      if (a.source != YildiznameArtifactSource.narrativeV1) continue;
      if (existingIds != null && !existingIds.contains(a.id)) continue;
      if (excludeSemanticFingerprint != null &&
          excludeSemanticFingerprint.isNotEmpty &&
          a.semanticFingerprint == excludeSemanticFingerprint) {
        continue;
      }
      final refs = YildiznameNarrativePayload.acceptedThemeRefs(a.payload);
      if (refs.isEmpty) continue;
      final labels = _requestLabels(a.payload);
      for (final ref in refs) {
        final acc = byTheme.putIfAbsent(ref, () => _Acc(ref));
        if (acc.ids.add(a.id)) {
          acc.count += 1;
          if (a.createdAtUtc.isAfter(acc.latest)) {
            acc.latest = a.createdAtUtc;
          }
          final label = labels[ref];
          if (label != null && label.isNotEmpty) acc.label = label;
        }
      }
    }
    final out = <YildiznameRecurringTheme>[];
    for (final acc in byTheme.values) {
      if (acc.count < 2) continue;
      out.add(
        YildiznameRecurringTheme(
          themeRef: acc.themeRef,
          label: acc.label.isEmpty ? acc.themeRef : acc.label,
          supportCount: acc.count,
          sourceArtifactIds: acc.ids.toList()..sort(),
          latestOccurredAt: acc.latest,
        ),
      );
    }
    out.sort((a, b) {
      final c = b.supportCount.compareTo(a.supportCount);
      if (c != 0) return c;
      final t = b.latestOccurredAt.compareTo(a.latestOccurredAt);
      if (t != 0) return t;
      return a.themeRef.compareTo(b.themeRef);
    });
    return out;
  }

  static Map<String, String> _requestLabels(Map<String, dynamic> payload) {
    final request = YildiznameNarrativePayload.requestOf(payload);
    if (request == null) return {};
    final themes = request['discoveryThemes'];
    if (themes is! List) return {};
    final map = <String, String>{};
    for (final t in themes) {
      if (t is! Map) continue;
      final ref = t['themeRef']?.toString() ?? '';
      final label = t['label']?.toString() ?? '';
      if (ref.isNotEmpty) map[ref] = label;
    }
    return map;
  }
}

class _Acc {
  _Acc(this.themeRef);
  final String themeRef;
  String label = '';
  int count = 0;
  DateTime latest = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  final Set<String> ids = {};
}
