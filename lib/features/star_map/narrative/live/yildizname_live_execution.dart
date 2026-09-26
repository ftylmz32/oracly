/// Phase 8B — typed live Narrative execution outcomes (UI-safe).
library;

import 'package:flutter/foundation.dart';

import '../../artifacts/yildizname_artifact.dart';
import '../../result/yildizname_result_presentation.dart';
import 'yildizname_pending_narrative_completion.dart';

enum YildiznameLiveExecutionKind {
  legacyLocal,
  ready,
  ownerUnavailable,
  invalidEvidence,
  aiUnavailable,
  generationFailed,
  persistencePending,
  ownerChanged,
  flagDisabled,
}

@immutable
final class YildiznameLiveExecution {
  const YildiznameLiveExecution._({
    required this.kind,
    this.presentation,
    this.artifact,
    this.pending,
    this.providerCallCount = 0,
  });

  factory YildiznameLiveExecution.legacyLocal() =>
      const YildiznameLiveExecution._(kind: YildiznameLiveExecutionKind.legacyLocal);

  factory YildiznameLiveExecution.ready({
    required YildiznameResultPresentation presentation,
    required YildiznameArtifact artifact,
    int providerCallCount = 0,
  }) =>
      YildiznameLiveExecution._(
        kind: YildiznameLiveExecutionKind.ready,
        presentation: presentation,
        artifact: artifact,
        providerCallCount: providerCallCount,
      );

  factory YildiznameLiveExecution.failure(
    YildiznameLiveExecutionKind kind, {
    YildiznamePendingNarrativeCompletion? pending,
    int providerCallCount = 0,
  }) =>
      YildiznameLiveExecution._(
        kind: kind,
        pending: pending,
        providerCallCount: providerCallCount,
      );

  final YildiznameLiveExecutionKind kind;
  final YildiznameResultPresentation? presentation;
  final YildiznameArtifact? artifact;
  final YildiznamePendingNarrativeCompletion? pending;
  final int providerCallCount;

  bool get isReady => kind == YildiznameLiveExecutionKind.ready;
  bool get isLegacy => kind == YildiznameLiveExecutionKind.legacyLocal;
  bool get canRetryPersistence =>
      kind == YildiznameLiveExecutionKind.persistencePending && pending != null;
}
