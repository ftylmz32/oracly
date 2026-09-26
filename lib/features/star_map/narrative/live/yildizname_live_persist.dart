/// Phase 8B — persist accepted Narrative result + build live presentation.
library;

import '../../artifacts/yildizname_artifact.dart';
import '../../artifacts/yildizname_artifact_exceptions.dart';
import 'yildizname_live_execution.dart';
import 'yildizname_live_orchestrator_deps.dart';
import 'yildizname_live_owner_snapshot.dart';
import 'yildizname_live_presentation_builder.dart';
import 'yildizname_pending_narrative_completion.dart';

final class YildiznameLivePersist {
  YildiznameLivePersist(this._deps);

  final YildiznameLiveOrchestratorDeps _deps;

  Future<YildiznameLiveExecution> complete(
    YildiznamePendingNarrativeCompletion pending, {
    YildiznameLiveOwnerSnapshot? expected,
  }) async {
    final snap = expected ??
        YildiznameLiveOwnerSnapshot(
          ownerId: pending.ownerId,
          epoch: pending.ownerEpoch,
        );
    if (!snap.matches(_deps.storage) ||
        snap.ownerId != pending.ownerId ||
        snap.epoch != pending.ownerEpoch) {
      return YildiznameLiveExecution.failure(
        YildiznameLiveExecutionKind.ownerChanged,
        providerCallCount: pending.providerCallCount,
      );
    }
    if (!_deps.flagEnabled()) {
      return YildiznameLiveExecution.failure(
        YildiznameLiveExecutionKind.flagDisabled,
        pending: pending,
        providerCallCount: pending.providerCallCount,
      );
    }

    late final YildiznameArtifact artifact;
    try {
      artifact = await _deps.completion.complete(
        ownerId: pending.ownerId,
        request: pending.request,
        result: pending.result,
        evidenceFingerprint: pending.evidenceFingerprint,
        semanticFingerprint: pending.semanticFingerprint,
        createdAtUtc: pending.createdAtUtc,
      );
    } catch (_) {
      return YildiznameLiveExecution.failure(
        YildiznameLiveExecutionKind.persistencePending,
        pending: pending,
        providerCallCount: pending.providerCallCount,
      );
    }

    if (!snap.matches(_deps.storage)) {
      try {
        await _deps.artifacts.delete(artifact.id);
      } catch (_) {}
      return YildiznameLiveExecution.failure(
        YildiznameLiveExecutionKind.ownerChanged,
        providerCallCount: pending.providerCallCount,
      );
    }

    try {
      _deps.onArtifactPersisted?.call();
    } catch (_) {}

    List<YildiznameArtifact> history = const [];
    try {
      history = await _deps.artifacts.getAll();
    } on YildiznameArtifactOwnerUnavailableException {
      history = const [];
    } catch (_) {}

    return YildiznameLiveExecution.ready(
      presentation: YildiznameLivePresentationBuilder.build(
        request: pending.request,
        result: pending.result,
        artifact: artifact,
        history: history,
        chromeLocale: pending.languageCode,
      ),
      artifact: artifact,
      providerCallCount: pending.providerCallCount,
    );
  }
}
