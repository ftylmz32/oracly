/// Pure continuity projector — Phase 6 memory ∩ current accepted themes.
///
/// Never treats stored `discoveryThemes` alone as recurrence proof.
///
/// Identity / owner fail-closed rules (Phase 7D.1):
/// - Current artifact ID is always stripped from history before Phase 6.
/// - Current must have a non-empty semanticFingerprint; otherwise EMPTY
///   (without operation identity we cannot prove another ID is not the
///   same logical reading).
/// - Current ownerId must be non-blank; history is filtered to same owner
///   (trim-only, matching repository semantics) before Phase 6.
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

  /// Returns [empty] when evidence fails closed. Does not mutate inputs.
  static YildiznameContinuityPresentation project({
    required YildiznameArtifact current,
    required Iterable<YildiznameArtifact> history,
    String? languageCode,
  }) {
    if (current.source != YildiznameArtifactSource.narrativeV1) {
      return YildiznameContinuityPresentation.empty;
    }
    final owner = current.ownerId.trim();
    if (owner.isEmpty) return YildiznameContinuityPresentation.empty;

    // Without a durable semantic operation id, another stored row could be
    // the same reading under a different artifact id — refuse continuity.
    final semantic = (current.semanticFingerprint ?? '').trim();
    if (semantic.isEmpty) return YildiznameContinuityPresentation.empty;

    final currentKeys = _currentAcceptedKeys(current.payload);
    if (currentKeys.isEmpty) return YildiznameContinuityPresentation.empty;

    final candidates = <YildiznameArtifact>[
      for (final a in history)
        if (a.id != current.id && a.ownerId.trim() == owner) a,
    ];

    final prior = YildiznameArtifactMemory.recurringThemes(
      candidates,
      excludeSemanticFingerprint: semantic,
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
      if (label == null || label.trim().isEmpty) continue;
      final key = YildiznameThemeIdentity.keyFor(label);
      if (key.isNotEmpty) keys.add(key);
    }
    return keys;
  }
}
