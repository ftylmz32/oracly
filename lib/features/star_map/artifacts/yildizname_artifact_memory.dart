/// Recurring themes from Narrative V1 artifacts only.
///
/// Historical identity = resolved label → [YildiznameThemeIdentity.keyFor].
/// Request-local `theme.N` refs are never compared across artifacts.
library;

import 'yildizname_artifact.dart';
import 'yildizname_artifact_source.dart';
import 'yildizname_narrative_payload.dart';
import 'yildizname_theme_identity.dart';

final class YildiznameRecurringTheme {
  const YildiznameRecurringTheme({
    required this.themeKey,
    required this.label,
    required this.supportCount,
    required this.sourceArtifactIds,
    required this.latestOccurredAt,
  });

  /// Local history identity (`yth_…`) — not a provider themeRef.
  final String themeKey;
  final String label;
  final int supportCount;
  final List<String> sourceArtifactIds;
  final DateTime latestOccurredAt;

  bool get isRecurring => supportCount >= 2;
}

abstract final class YildiznameArtifactMemory {
  YildiznameArtifactMemory._();

  /// Themes whose resolved labels appear in ≥2 distinct Narrative V1 artifacts.
  static List<YildiznameRecurringTheme> recurringThemes(
    Iterable<YildiznameArtifact> artifacts, {
    String? excludeSemanticFingerprint,
    Set<String>? existingIds,
  }) {
    final byKey = <String, _Acc>{};
    for (final a in artifacts) {
      if (a.source != YildiznameArtifactSource.narrativeV1) continue;
      if (existingIds != null && !existingIds.contains(a.id)) continue;
      if (excludeSemanticFingerprint != null &&
          excludeSemanticFingerprint.isNotEmpty &&
          a.semanticFingerprint == excludeSemanticFingerprint) {
        continue;
      }
      final accepted = YildiznameNarrativePayload.acceptedThemeRefs(a.payload);
      if (accepted.isEmpty) continue;
      final requestMap = _requestLabels(a.payload);
      // One artifact contributes at most one support per canonical theme.
      final seenKeys = <String>{};
      for (final ref in accepted) {
        final label = requestMap[ref];
        if (label == null || label.trim().isEmpty) continue; // unknown ref
        final key = YildiznameThemeIdentity.keyFor(label);
        if (key.isEmpty) continue;
        if (!seenKeys.add(key)) continue;
        final acc = byKey.putIfAbsent(key, () => _Acc(key, label.trim()));
        if (acc.ids.add(a.id)) {
          acc.count += 1;
          if (a.createdAtUtc.isAfter(acc.latest)) {
            acc.latest = a.createdAtUtc;
          }
        }
      }
    }
    final out = <YildiznameRecurringTheme>[];
    for (final acc in byKey.values) {
      if (acc.count < 2) continue;
      out.add(
        YildiznameRecurringTheme(
          themeKey: acc.themeKey,
          label: acc.label,
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
      return a.themeKey.compareTo(b.themeKey);
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
  _Acc(this.themeKey, this.label);
  final String themeKey;
  String label;
  int count = 0;
  DateTime latest = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  final Set<String> ids = {};
}
