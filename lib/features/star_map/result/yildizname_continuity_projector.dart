/// Pure continuity projector — Phase 6 memory ∩ current accepted themes.
///
/// Never treats stored `discoveryThemes` alone as recurrence proof.
library;

import '../artifacts/yildizname_artifact.dart';
import '../artifacts/yildizname_artifact_memory.dart';
import '../artifacts/yildizname_artifact_source.dart';
import '../artifacts/yildizname_narrative_payload.dart';
import '../artifacts/yildizname_theme_identity.dart';
import 'yildizname_continuity_presentation.dart';
import 'yildizname_result_chrome.dart';

abstract final class YildiznameContinuityProjector {
  YildiznameContinuityProjector._();

  /// Editorial cap — restrained archive echo, never a timeline.
  static const int maxThemes = 3;

  /// [history] must already be owner-safe. Returns [empty] when evidence fails.
  static YildiznameContinuityPresentation project({
    required YildiznameArtifact current,
    required Iterable<YildiznameArtifact> history,
    String? languageCode,
  }) {
    if (current.source != YildiznameArtifactSource.narrativeV1) {
      return YildiznameContinuityPresentation.empty;
    }
    final currentKeys = _currentAcceptedKeys(current.payload);
    if (currentKeys.isEmpty) return YildiznameContinuityPresentation.empty;

    final prior = YildiznameArtifactMemory.recurringThemes(
      history,
      excludeSemanticFingerprint: current.semanticFingerprint,
    );
    if (prior.isEmpty) return YildiznameContinuityPresentation.empty;

    final labels = <String>[];
    for (final t in prior) {
      if (!currentKeys.contains(t.themeKey)) continue;
      labels.add(t.label);
      if (labels.length >= maxThemes) break;
    }
    if (labels.isEmpty) return YildiznameContinuityPresentation.empty;

    final lang = YildiznameResultChrome.language(languageCode);
    return YildiznameContinuityPresentation(
      heading: YildiznameResultChrome.continuityHeading(lang),
      body: YildiznameResultChrome.continuityBody(lang),
      labels: List.unmodifiable(labels),
    );
  }

  /// Resolve CURRENT accepted themeRefs against THIS artifact's request only.
  static Set<String> _currentAcceptedKeys(Map<String, dynamic> payload) {
    final accepted = YildiznameNarrativePayload.acceptedThemeRefs(payload);
    if (accepted.isEmpty) return {};
    final request = YildiznameNarrativePayload.requestOf(payload);
    if (request == null) return {};
    final themes = request['discoveryThemes'];
    if (themes is! List) return {};
    final refToLabel = <String, String>{};
    for (final t in themes) {
      if (t is! Map) continue;
      final ref = t['themeRef']?.toString() ?? '';
      final label = t['label']?.toString() ?? '';
      if (ref.isNotEmpty) refToLabel[ref] = label;
    }
    final keys = <String>{};
    for (final ref in accepted) {
      final label = refToLabel[ref];
      if (label == null || label.trim().isEmpty) continue; // unknown ref
      final key = YildiznameThemeIdentity.keyFor(label);
      if (key.isNotEmpty) keys.add(key);
    }
    return keys;
  }
}
