/// BATCH 5G — the single place that wraps portrait draw, provider retry,
/// uniqueness checks, authoritative interpretation, bounded interpretation
/// repair, and the Journal upsert into ONE ReadingOperation claim. Internal
/// retries (portrait attempt 2, the bounded manual interpretation retry)
/// reuse the same logical id and never create a second operation, a second
/// gem-operation, or a second Journal row.
///
/// This does not replace SoulMateGenerationRunner/SoulMateGenerationPolicy —
/// it wraps them. Portrait reliability (4B), authoritative-only
/// interpretation (4C), and identity/uniqueness (4D) stay exactly as they
/// already were; this file only adds the durable claim boundary around
/// them so the whole thing survives an app kill.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../ai/production/ai_request_fingerprint.dart';
import '../../reading_operation/models/reading_failure_code.dart';
import '../../reading_operation/models/reading_operation_status.dart';
import '../../reading_operation/providers/reading_live_provider.dart';
import '../../reading_operation/services/reading_live_flow.dart';
import '../presentation/screens/soul_mate_draw_persistence.dart';
import 'soul_mate_draw_action.dart';
import 'soul_mate_connected_memory.dart';
import 'soul_mate_draw_port.dart';
import 'soul_mate_generation_identity.dart';
import 'soul_mate_generation_policy.dart';
import 'soul_mate_identity.dart';
import 'soul_mate_interpretation_context.dart';
import 'soul_mate_paid_draw.dart';
import '../data/soul_mate_interpretation_catalogue.dart';
import '../providers/soul_mate_providers.dart';
import '../providers/soul_mate_saved_provider.dart';

enum SoulMateOrchestrationKind {
  /// Portrait + authoritative interpretation both saved. Operation is ready.
  success,

  /// Portrait saved, interpretation failed or is not yet authoritative.
  /// The operation itself is failed (it cannot attach ready without both),
  /// but the portrait remains usable via the saved result.
  partial,

  /// Nothing usable — the caller should show a plain failure.
  failed,

  /// The claim window was not obtained (another instance is mid-lease, or
  /// the near-zero wait had not elapsed within the polling budget). Not a
  /// failure — the caller should treat this like "still generating".
  processing,

  /// A prior run of this exact request already completed; reopened with
  /// zero AI calls.
  reopened,

  /// No proxy configured, or the operation service is unavailable. Fail
  /// closed — never fall back to a direct, unclaimed AI call.
  unavailable,
}

class SoulMateOrchestrationOutcome {
  const SoulMateOrchestrationOutcome({
    required this.kind,
    this.draw,
    this.interpretation,
    this.savedId,
  });

  final SoulMateOrchestrationKind kind;
  final SoulMateDrawResult? draw;
  final SoulMateReadingParts? interpretation;
  final String? savedId;
}

class SoulMateReadingOrchestrator {
  SoulMateReadingOrchestrator();

  /// Total interpretation attempts allowed per logical operation — one
  /// automatic attempt inside [draw], plus at most this many minus one
  /// manual retries. Locked at 2 (same shape as the portrait's own
  /// SoulMateGenerationPolicy.maxAttempts): one automatic try, one manual
  /// repair. A third attempt is refused, not queued.
  static const int interpretationAttemptBound = 2;

  static const int _pollAttempts = 8;
  static const Duration _pollDelay = Duration(milliseconds: 250);

  int _interpretationAttempts = 0;

  Future<SoulMateOrchestrationOutcome> draw({
    required WidgetRef ref,
    required BuildContext context,
    required SoulMateDrawRequest request,
    required bool fresh,
    // Fired the moment the portrait itself succeeds, before interpretation
    // and persistence run — the operation claim stays held underneath
    // (interpretation/repair/Journal upsert still complete inside the SAME
    // claim), this only lets the caller render the portrait immediately
    // instead of waiting on the slower interpretation+disk-write tail.
    void Function(SoulMateDrawResult portrait)? onPortraitReady,
  }) async {
    final runner = ref.read(readingFeatureRunnerProvider);
    if (runner == null) {
      return const SoulMateOrchestrationOutcome(
        kind: SoulMateOrchestrationKind.unavailable,
      );
    }
    final flow = runner.flow;
    final storage = ref.read(localStorageProvider);
    final owner = SoulMateDrawAction.ownerOf(ref);
    final birthIso = _iso(request.birthDate);
    final fingerprint = AiRequestFingerprint.soulMate(
      name: request.name,
      birthDate: birthIso,
      gender: request.gender?.name,
      intention: request.intention,
    );

    // Resolve the logical id ourselves and persist it before the runner
    // ever runs, so the runner's own internal resolve() (fresh: false)
    // reads this exact record back and reuses this exact id — one id
    // shared by the ReadingOperation's sourceRequestId, the gem-guard's
    // existingOperationId, and the saved-result/Journal recordId.
    final logicalId = await SoulMateGenerationIdentity.resolve(
      storage: storage,
      ownerId: owner,
      fingerprint: fingerprint,
      fresh: fresh,
    );
    await SoulMateGenerationIdentity.write(
      storage,
      ownerId: owner,
      logicalId: logicalId,
      fingerprint: fingerprint,
      phase: SoulMateGenerationPhase.submitting,
      name: request.name,
      birthIso: birthIso,
      gender: request.gender?.name,
      intention: request.intention,
    );
    _interpretationAttempts = 0;

    var begun = await flow.begin(
      readingType: ReadingType.soulmate,
      sourceRequestId: logicalId,
    );
    if (begun.kind == ReadingLiveKind.failed) {
      // Soulmate's own retry semantics deliberately reuse `logicalId` even
      // after a failed attempt (SoulMateGenerationIdentity — unrelated to
      // this operation layer, and not something this batch may redesign),
      // but a ReadingOperation can never move from failed back to ready.
      // A genuine retry needs a fresh operation under a different
      // sourceRequestId; logicalId itself (gem-guard/Journal continuity)
      // is untouched.
      final retrySourceId =
          '$logicalId-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
      begun = await flow.begin(
        readingType: ReadingType.soulmate,
        sourceRequestId: retrySourceId,
      );
    }
    final beginSnapshot = begun.snapshot;
    if (beginSnapshot == null) {
      return const SoulMateOrchestrationOutcome(
        kind: SoulMateOrchestrationKind.unavailable,
      );
    }
    if (begun.kind == ReadingLiveKind.failed) {
      return const SoulMateOrchestrationOutcome(
        kind: SoulMateOrchestrationKind.failed,
      );
    }
    if (begun.kind == ReadingLiveKind.ready) {
      return _reopen(ref, beginSnapshot.resultId);
    }

    final inputGateway = ref.read(readingOperationInputGatewayProvider);
    final inputSaved =
        inputGateway != null &&
        await inputGateway.save(
          operationId: beginSnapshot.operationId,
          fields: {
            'name': request.name,
            'birthIso': birthIso,
            if (request.gender != null) 'gender': request.gender!.name,
            if ((request.intention ?? '').isNotEmpty)
              'intention': request.intention!,
          },
        );
    if (!inputSaved) {
      await flow.failFinal(beginSnapshot.operationId);
      return const SoulMateOrchestrationOutcome(
        kind: SoulMateOrchestrationKind.unavailable,
      );
    }

    ReadingLiveState claim = const ReadingLiveState(
      kind: ReadingLiveKind.processing,
      snapshot: null,
    );
    for (var attempt = 0; attempt < _pollAttempts; attempt++) {
      claim = await flow.claimIfEligible(beginSnapshot.operationId);
      if (claim.execute) break;
      await Future<void>.delayed(_pollDelay);
    }
    if (!claim.execute) {
      return const SoulMateOrchestrationOutcome(
        kind: SoulMateOrchestrationKind.processing,
      );
    }

    SoulMateDrawResult? drawResult;
    try {
      drawResult = await ref
          .read(soulMateGenerationRunnerProvider)
          .start(
            storage: storage,
            ownerId: owner,
            fingerprint: fingerprint,
            fresh: false,
            name: request.name,
            birthIso: birthIso,
            gender: request.gender?.name,
            intention: request.intention,
            drawOnce: (id) async {
              final result = await SoulMatePaidDraw.run(
                ref: ref,
                context: context,
                request: request,
                existingOperationId: id,
              );
              return result ?? const SoulMateDrawResult.declined();
            },
          );
    } catch (_) {
      drawResult = null;
    }

    if (drawResult == null || drawResult.declined || !drawResult.hasPortrait) {
      await flow.failFinal(beginSnapshot.operationId);
      return SoulMateOrchestrationOutcome(
        kind: SoulMateOrchestrationKind.failed,
        draw: drawResult,
      );
    }

    onPortraitReady?.call(drawResult);

    _interpretationAttempts = 1;
    final interpretation = await _runInterpretation(ref, request, drawResult);
    final savedId = await SoulMateDrawPersistence.persistWithService(
      service: ref.read(soulMateResultServiceProvider),
      request: request,
      imageBytes: drawResult.imageBytes!,
      recordId: drawResult.operationId,
      expectedOwnerId: owner,
      parts: interpretation,
      identity: drawResult.identity,
    );

    if (interpretation != null &&
        interpretation.authoritative &&
        savedId != null) {
      await flow.complete(
        operationId: beginSnapshot.operationId,
        resultId: savedId,
      );
      return SoulMateOrchestrationOutcome(
        kind: SoulMateOrchestrationKind.success,
        draw: drawResult,
        interpretation: interpretation,
        savedId: savedId,
      );
    }

    // Portrait survives even though the operation cannot attach ready
    // without an authoritative interpretation too (4C/Section 7).
    await flow.failFinal(beginSnapshot.operationId);
    return SoulMateOrchestrationOutcome(
      kind: SoulMateOrchestrationKind.partial,
      draw: drawResult,
      savedId: savedId,
    );
  }

  /// Bounded manual repair. Same operation, same portrait bytes, no new
  /// image call, no new logical operation, no duplicate Journal row —
  /// upserts the same [recordId]. Returns null once the bound is spent.
  Future<SoulMateReadingParts?> retryInterpretation({
    required WidgetRef ref,
    required SoulMateDrawRequest request,
    required SoulMateDrawResult portrait,
    required String ownerId,
  }) async {
    if (_interpretationAttempts >= interpretationAttemptBound) return null;
    if (!portrait.hasPortrait) return null;
    _interpretationAttempts += 1;
    final interpretation = await _runInterpretation(ref, request, portrait);
    await SoulMateDrawPersistence.persistWithService(
      service: ref.read(soulMateResultServiceProvider),
      request: request,
      imageBytes: portrait.imageBytes!,
      recordId: portrait.operationId,
      expectedOwnerId: ownerId,
      parts: interpretation,
      identity: portrait.identity,
    );
    return interpretation;
  }

  bool get canRetryInterpretation =>
      _interpretationAttempts < interpretationAttemptBound;

  Future<SoulMateReadingParts?> _runInterpretation(
    WidgetRef ref,
    SoulMateDrawRequest request,
    SoulMateDrawResult portrait,
  ) async {
    final memorySummary = SoulMateConnectedMemory.select(
      retriever: ref.read(oraclyMemoryRetrieverProvider),
      intention: request.intention,
    );
    final outcome = await ref
        .read(soulMateInterpretationPortProvider)
        .interpret(
          SoulMateInterpretationContext.fromRequest(
            request,
            identity: portrait.identity,
            memorySummary: memorySummary,
          ),
        );
    if (!outcome.hasText || outcome.parts?.authoritative != true) return null;
    return outcome.parts;
  }

  Future<SoulMateOrchestrationOutcome> _reopen(
    WidgetRef ref,
    String? resultId,
  ) async {
    if (resultId == null) {
      return const SoulMateOrchestrationOutcome(
        kind: SoulMateOrchestrationKind.failed,
      );
    }
    final loaded = await ref
        .read(soulMateResultServiceProvider)
        .latestWithPortrait();
    if (loaded == null || loaded.meta.id != resultId) {
      return const SoulMateOrchestrationOutcome(
        kind: SoulMateOrchestrationKind.failed,
      );
    }
    return SoulMateOrchestrationOutcome(
      kind: SoulMateOrchestrationKind.reopened,
      draw: SoulMateDrawResult.success(
        imageBytes: loaded.bytes,
        identity: loaded.meta.identity,
      ).tagged(resultId),
      interpretation: loaded.meta.hasAuthoritativeInterpretation
          ? loaded.meta.parts
          : null,
      savedId: resultId,
    );
  }

  static String _iso(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Passive-only recovery — mirrors Coffee/Palm's recoverActive(): reflect
  /// status, never auto-claim or re-run the pipeline.
  ///
  /// LEGACY (executionMode absent) path only. Kept unchanged for every
  /// pre-SMD1 (1.0.0+26091304 and earlier) operation still on the server —
  /// see [recoverDurable] for the new server-authoritative equivalent.
  static Future<SoulMateRecoveryState> recoverActive(WidgetRef ref) async {
    final runner = ref.read(readingFeatureRunnerProvider);
    if (runner == null) return const SoulMateRecoveryState.idle();
    final state = await runner.flow.recover(ReadingType.soulmate);
    if (state.kind == ReadingLiveKind.processing) {
      return SoulMateRecoveryState.processing(state.snapshot?.operationId);
    }
    if (state.kind == ReadingLiveKind.failed) {
      return const SoulMateRecoveryState.failed();
    }
    return const SoulMateRecoveryState.idle();
  }

  // ---------------------------------------------------------------------
  // SMD1 — server-authoritative Soulmate. Submission returns immediately
  // (portrait + interpretation + persistence all run in the durable
  // worker, surviving app kill/restart); completion is discovered by
  // polling the SAME `/v1/reading-flow/active` endpoint [recoverActive]
  // already used, via [recoverDurable] below.
  // ---------------------------------------------------------------------

  /// Creates a durable (`executionMode: 'durable'`) Soulmate operation and
  /// saves its structured input. Never claims or calls a provider
  /// client-side — from a successful return, the server owns the rest of
  /// the pipeline even if this screen is never seen again.
  Future<SoulMateDurableOutcome> drawDurable({
    required WidgetRef ref,
    required SoulMateDrawRequest request,
    required bool fresh,
  }) async {
    final runner = ref.read(readingFeatureRunnerProvider);
    if (runner == null) {
      return const SoulMateDurableOutcome(
        kind: SoulMateDurableKind.unavailable,
      );
    }
    final storage = ref.read(localStorageProvider);
    final owner = SoulMateDrawAction.ownerOf(ref);
    final birthIso = _iso(request.birthDate);
    final fingerprint = AiRequestFingerprint.soulMate(
      name: request.name,
      birthDate: birthIso,
      gender: request.gender?.name,
      intention: request.intention,
    );
    final logicalId = await SoulMateGenerationIdentity.resolve(
      storage: storage,
      ownerId: owner,
      fingerprint: fingerprint,
      fresh: fresh,
    );
    await SoulMateGenerationIdentity.write(
      storage,
      ownerId: owner,
      logicalId: logicalId,
      fingerprint: fingerprint,
      phase: SoulMateGenerationPhase.submitting,
      name: request.name,
      birthIso: birthIso,
      gender: request.gender?.name,
      intention: request.intention,
    );

    final fields = {
      'name': request.name,
      'birthIso': birthIso,
      if (request.gender != null) 'gender': request.gender!.name,
      if ((request.intention ?? '').isNotEmpty) 'intention': request.intention!,
    };

    var begun = await runner.submitSoulmateDurable(
      sourceRequestId: logicalId,
      fields: fields,
    );
    // A failed operation can never become ready, and `sourceRequestId`
    // create-if-absent means an existing LEGACY (non-durable) record under
    // this same reused `logicalId` — e.g. the stale-legacy case, whose
    // local phase never reached `succeeded` — would otherwise be handed
    // back unchanged here, `executionMode` and all: this build would then
    // start "durably" polling an operation no durable worker will ever
    // touch. Either case needs the SAME fix: a genuinely new operation.
    final collidedWithNonDurable =
        begun.snapshot != null &&
        !begun.snapshot!.durable &&
        (begun.kind == ReadingLiveKind.waiting ||
            begun.kind == ReadingLiveKind.processing);
    if (begun.kind == ReadingLiveKind.failed || collidedWithNonDurable) {
      final retrySourceId =
          '$logicalId-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
      begun = await runner.submitSoulmateDurable(
        sourceRequestId: retrySourceId,
        fields: fields,
      );
    }
    final snapshot = begun.snapshot;
    if (snapshot == null) {
      return const SoulMateDurableOutcome(
        kind: SoulMateDurableKind.unavailable,
      );
    }
    if (begun.kind == ReadingLiveKind.failed) {
      return SoulMateDurableOutcome(
        kind: SoulMateDurableKind.failed,
        failureCode: snapshot.failureCode,
      );
    }
    if (begun.kind == ReadingLiveKind.ready) {
      return _finishReady(
        ref,
        snapshot.operationId,
        activeSince: snapshot.createdAt,
      );
    }
    return SoulMateDurableOutcome(
      kind: SoulMateDurableKind.active,
      activeSince: snapshot.createdAt,
    );
  }

  /// Polls the durable Soulmate operation's current server state. Safe to
  /// call on screen open, after a controller rebuild, or from a timer —
  /// it only ever observes; it never claims, executes, or creates a
  /// second operation.
  static Future<SoulMateDurableOutcome> recoverDurable(WidgetRef ref) async {
    final runner = ref.read(readingFeatureRunnerProvider);
    if (runner == null) {
      // A passive recovery check with nothing configured to check against
      // is "nothing to observe here" (`none`), never a failure — unlike
      // `drawDurable`, no submission was ever attempted on this call, so
      // there is nothing to report as unavailable. `none` lets the caller
      // fall through to the legacy/restore-saved path instead of showing
      // a false error on an otherwise-untouched screen.
      return const SoulMateDurableOutcome(kind: SoulMateDurableKind.none);
    }
    final state = await runner.flow.recover(ReadingType.soulmate);
    final snapshot = state.snapshot;
    // `/v1/reading-flow/active` returns whatever operation is active
    // REGARDLESS of executionMode — it is the exact same endpoint
    // `recoverActive()` (the legacy path) already polls. `durable` is the
    // only signal that distinguishes "this build's own submission" from
    // a legacy (pre-SMD1) record; treating a non-durable snapshot as
    // authoritative here would let a stale legacy operation masquerade as
    // an actively-progressing durable one (and poll it forever). Defer
    // entirely to the legacy path in that case.
    if (snapshot == null || !snapshot.durable) {
      return const SoulMateDurableOutcome(kind: SoulMateDurableKind.none);
    }
    if (state.kind == ReadingLiveKind.failed) {
      return SoulMateDurableOutcome(
        kind: SoulMateDurableKind.failed,
        failureCode: snapshot.failureCode,
      );
    }
    if (state.kind == ReadingLiveKind.ready) {
      return _finishReady(
        ref,
        snapshot.operationId,
        activeSince: snapshot.createdAt,
      );
    }
    // waiting / processing — the near-zero Soulmate wait means "waiting"
    // is only ever transient; both render as the same active/observing
    // state to the caller.
    return SoulMateDurableOutcome(
      kind: SoulMateDurableKind.active,
      activeSince: snapshot.createdAt,
    );
  }

  /// Fetches the authoritative result + authenticated portrait for a
  /// `ready` durable operation and persists it to the local Journal
  /// exactly once (upserts by `operationId`, so controller recreation,
  /// navigation rebuild, and process restart all converge on the SAME
  /// saved row — SMD1 §13). A transient fetch failure here does NOT mean
  /// the operation failed server-side — it stays `active` so the caller
  /// keeps observing rather than showing a false error.
  static Future<SoulMateDurableOutcome> _finishReady(
    WidgetRef ref,
    String operationId, {
    DateTime? activeSince,
  }) async {
    final runner = ref.read(readingFeatureRunnerProvider);
    if (runner == null) {
      return SoulMateDurableOutcome(
        kind: SoulMateDurableKind.active,
        activeSince: activeSince,
      );
    }
    final result = await runner.flow.fetchCompletedResult(operationId);
    final portrait = await runner.flow.fetchSoulmatePortrait(operationId);
    if (result == null || portrait == null) {
      return SoulMateDurableOutcome(
        kind: SoulMateDurableKind.active,
        activeSince: activeSince,
      );
    }
    final data = result.result;
    final identity = SoulMateIdentity.fromMap(data['identity']);
    final parts = SoulMateReadingParts(
      energy: _text(data['personality']),
      attraction: _text(data['attraction']),
      dynamics: _text(data['dynamic']),
      feeling: _text(data['feeling']),
      yourSide: _text(data['challenge']),
      meeting: _text(data['meeting']),
      authoritative: true,
    );
    final imageBytes = base64Decode(portrait.imageBase64);

    final owner = SoulMateDrawAction.ownerOf(ref);
    // The durable worker's own request fields (name/birthIso/gender/
    // intention) were saved server-side at submission time — reading them
    // back here means Journal persistence works even on a cold recovery
    // (process restart) where no in-memory SoulMateDrawRequest survives.
    final savedFields = await ref
        .read(readingOperationInputGatewayProvider)
        ?.get(operationId);
    final birthIso = savedFields?['birthIso'];
    final birthDate = birthIso == null ? null : DateTime.tryParse(birthIso);
    // The authoritative result and portrait are already fetched from the
    // server at this point — a local Journal-write failure (disk error,
    // permission issue) must NEVER hide an already-completed result from
    // the user; it is a best-effort local cache, not the source of truth.
    // Only skip the write (not the render) when the request fields
    // genuinely cannot be reconstructed.
    String? savedId;
    if (savedFields != null &&
        savedFields['name'] != null &&
        birthDate != null) {
      final restored = SoulMateDrawRequest(
        name: savedFields['name']!,
        birthDate: birthDate,
        gender: savedFields['gender'] == 'feminine'
            ? SoulMateGenderPref.feminine
            : savedFields['gender'] == 'masculine'
            ? SoulMateGenderPref.masculine
            : null,
        intention: savedFields['intention'],
      );
      savedId = await SoulMateDrawPersistence.persistWithService(
        service: ref.read(soulMateResultServiceProvider),
        request: restored,
        imageBytes: imageBytes,
        recordId: operationId,
        expectedOwnerId: owner,
        parts: parts,
        identity: identity,
      );
    }
    return SoulMateDurableOutcome(
      kind: SoulMateDurableKind.ready,
      draw: SoulMateDrawResult.success(
        imageBytes: imageBytes,
        identity: identity,
      ).tagged(savedId ?? operationId),
      interpretation: parts,
      savedId: savedId,
    );
  }

  static String _text(Object? value) => value is String ? value : '';
}

enum SoulMateDurableKind {
  /// No active durable Soulmate operation at all.
  none,

  /// Still waiting/processing server-side — keep polling.
  active,

  /// Ready: `draw`/`interpretation`/`savedId` are populated.
  ready,

  /// Server-final failure.
  failed,

  /// No proxy configured, or the operation service is unavailable.
  unavailable,
}

class SoulMateDurableOutcome {
  const SoulMateDurableOutcome({
    required this.kind,
    this.draw,
    this.interpretation,
    this.savedId,
    this.activeSince,
    this.failureCode = ReadingFailureCode.unknown,
  });

  final SoulMateDurableKind kind;
  final SoulMateDrawResult? draw;
  final SoulMateReadingParts? interpretation;
  final String? savedId;

  /// Server-authoritative operation creation time. UI-only elapsed-time
  /// presentation may use this; it never changes operation validity.
  final DateTime? activeSince;

  /// R3.1 — allow-listed failure class when [kind] is failed.
  final ReadingFailureCode failureCode;
}

class SoulMateRecoveryState {
  const SoulMateRecoveryState._(this.kind, [this.operationId]);
  const SoulMateRecoveryState.idle() : this._(SoulMateRecoveryKind.idle);
  const SoulMateRecoveryState.processing([String? operationId])
    : this._(SoulMateRecoveryKind.processing, operationId);
  const SoulMateRecoveryState.failed() : this._(SoulMateRecoveryKind.failed);

  final SoulMateRecoveryKind kind;

  /// The stale legacy operation's id, when known — used only to look up
  /// its already-saved structured input so a controlled retry can refill
  /// the form without asking the user to retype it.
  final String? operationId;
}

enum SoulMateRecoveryKind { idle, processing, failed }
