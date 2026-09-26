/// Phase 8B.2 — controlled fakes: held provider, held save, counted analytics.
library;

import 'dart:async';

import 'package:oracly_new/core/services/analytics_service.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_narrative_completion_service.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_request.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_narrative_structured_result.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_result_parser.dart';

import 'phase8b_approved_payload.dart';

/// Fake provider whose every call stays pending until [release].
class Phase8b2HeldGen {
  int calls = 0;
  final _held = <(Completer<YildiznameNarrativeStructuredResult>,
      YildiznameNarrativeRequest)>[];

  Future<YildiznameNarrativeStructuredResult> call({
    required YildiznameNarrativeRequest request,
    bool forceRefresh = false,
  }) {
    calls++;
    final c = Completer<YildiznameNarrativeStructuredResult>();
    _held.add((c, request));
    return c.future;
  }

  void release() {
    final (c, request) = _held.removeAt(0);
    c.complete(YildiznameResultParser.parse(phase8bApprovedPayload(request)));
  }
}

/// Completion that waits on [gate] before the real durable save.
class Phase8b2HeldCompletion extends YildiznameNarrativeCompletionService {
  Phase8b2HeldCompletion(super.repo);

  final gate = Completer<void>();
  int calls = 0;

  @override
  Future<YildiznameArtifact> complete({
    required String ownerId,
    required YildiznameNarrativeRequest request,
    required YildiznameNarrativeStructuredResult result,
    String? evidenceFingerprint,
    String? semanticFingerprint,
    String? policyVersion,
    DateTime? createdAtUtc,
  }) async {
    calls++;
    await gate.future;
    return super.complete(
      ownerId: ownerId,
      request: request,
      result: result,
      evidenceFingerprint: evidenceFingerprint,
      semanticFingerprint: semanticFingerprint,
      policyVersion: policyVersion,
      createdAtUtc: createdAtUtc,
    );
  }
}

class Phase8b2Analytics extends AnalyticsService {
  int completed = 0;

  @override
  void logStarMapCompleted() => completed++;
}
