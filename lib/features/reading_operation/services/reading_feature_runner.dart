/// Runs one feature pipeline only after the server grants a claim.
library;

import '../models/reading_operation_status.dart';
import 'reading_live_flow.dart';
import 'reading_operation_context.dart';
import 'reading_operation_input_gateway.dart';
import 'reading_staged_image_gateway.dart';
import 'reading_runtime_diagnostics.dart';

class ReadingFeatureRunner {
  ReadingFeatureRunner({
    required this.flow,
    this.stagedImages,
    this.inputs,
    this.serverOwnedCompletion = false,
    this.diagnostics = const DebugReadingRuntimeDiagnostics(),
  });

  final ReadingLiveFlow flow;
  final ReadingStagedImageGateway? stagedImages;
  /// SMD1 — Soulmate's durable-submission counterpart to [stagedImages]:
  /// no image bytes, just the small structured input record the durable
  /// worker needs to regenerate the same request server-side.
  final ReadingOperationInputGateway? inputs;
  final bool serverOwnedCompletion;
  final ReadingRuntimeDiagnostics diagnostics;

  /// SMD1 — submits a Soulmate operation as server-authoritative: creates
  /// the operation with `executionMode: durable`, saves the structured
  /// input, and returns immediately without ever claiming or running a
  /// provider client-side. From this point the durable worker owns
  /// portrait + interpretation + persistence; the caller only observes via
  /// `flow.recover(ReadingType.soulmate)` / `flow.fetchCompletedResult` /
  /// `flow.fetchSoulmatePortrait`.
  Future<ReadingLiveState> submitSoulmateDurable({
    required String sourceRequestId,
    required Map<String, String> fields,
  }) async {
    final begun = await flow.begin(
      readingType: ReadingType.soulmate,
      sourceRequestId: sourceRequestId,
      executionMode: 'durable',
    );
    final snapshot = begun.snapshot;
    if (snapshot == null ||
        begun.kind == ReadingLiveKind.failed ||
        begun.kind == ReadingLiveKind.ready) {
      return begun;
    }
    final gateway = inputs;
    final saved = gateway != null &&
        await gateway.save(operationId: snapshot.operationId, fields: fields);
    if (!saved) {
      await flow.failFinal(snapshot.operationId);
      return ReadingLiveState(
        kind: ReadingLiveKind.failed,
        snapshot: snapshot,
        failureStage: 'input_save',
      );
    }
    // Input is durably saved; the server now owns the rest of the pipeline
    // (the Cloud Task that runs it is scheduled for `readyAtMs`, which for
    // Soulmate is a near-zero, non-commercial wait — see
    // SOULMATE_NO_COMMERCIAL_WAIT_MS server-side). Report the operation's
    // real state rather than guessing a kind.
    return begun;
  }

  Future<ReadingLiveState> submit({
    required ReadingType readingType,
    required String sourceRequestId,
    required Future<String> Function() runPipeline,
    List<int>? imageBytes,
    String? mimeType,
    String? handSide,
  }) async {
    final begun = await flow.begin(
      readingType: readingType,
      sourceRequestId: sourceRequestId,
    );
    final beginSnapshot = begun.snapshot;
    if (beginSnapshot == null && begun.kind == ReadingLiveKind.failed) {
      diagnostics.record(
        ReadingRuntimeDiagnostic(
          feature: readingType.name,
          operationId: null,
          stage: begun.failureStage ?? 'begin',
          exceptionType: 'ReadingRuntimeException',
          safeMessage: begun.httpStatus == null
              ? 'transport_unavailable'
              : 'backend_rejected',
          httpStatus: begun.httpStatus,
          backendCode: begun.backendCode,
        ),
      );
    }
    final hasStagedInput =
        imageBytes != null || mimeType != null || handSide != null;
    if (beginSnapshot != null &&
        stagedImages != null &&
        hasStagedInput &&
        (readingType == ReadingType.coffee ||
            readingType == ReadingType.palm)) {
      final stager = stagedImages;
      if (stager == null || imageBytes == null || mimeType == null) {
        return ReadingLiveState(
          kind: ReadingLiveKind.failed,
          snapshot: beginSnapshot,
        );
      }
      final staged = await stager.stage(
        operationId: beginSnapshot.operationId,
        bytes: imageBytes,
        mimeType: mimeType,
        handSide: handSide,
      );
      if (!staged) {
        return ReadingLiveState(
          kind: ReadingLiveKind.failed,
          snapshot: beginSnapshot,
          failureStage: 'stage',
        );
      }
      // Coffee/Palm completion is server-owned once durable staging has
      // succeeded. The client observes waiting/processing/completed state;
      // it never claims or performs the paid provider call.
      if (serverOwnedCompletion) return begun;
    }
    return _claimAndExecute(begun: begun, runPipeline: runPipeline);
  }

  /// Re-checks an operation `submit` already created (and, for Coffee/Palm,
  /// already durably staged) and claims + executes it if it is now
  /// eligible. Never re-stages the image and never creates a second
  /// operation — `flow.begin` with the SAME `sourceRequestId` is idempotent
  /// and returns the existing record with a freshly recomputed
  /// `waitFinished` (the server derives it from `now >= readyAt` on every
  /// read, never a cached value from creation time).
  ///
  /// This is the missing other half of `submit`: once `submit` itself
  /// returns `waiting` because the operation's own wait had not elapsed
  /// yet, nothing previously ever called back to attempt the claim again —
  /// an operation could sit `waiting` forever even after becoming
  /// genuinely eligible. Callers are expected to invoke this once the
  /// snapshot's own countdown (`ReadingLiveState.displayRemaining`)
  /// reaches zero.
  Future<ReadingLiveState> resume({
    required ReadingType readingType,
    required String sourceRequestId,
    required Future<String> Function() runPipeline,
  }) {
    if (serverOwnedCompletion &&
        (readingType == ReadingType.coffee || readingType == ReadingType.palm)) {
      return flow.recover(readingType);
    }
    return flow
        .begin(readingType: readingType, sourceRequestId: sourceRequestId)
        .then(
          (begun) => _claimAndExecute(begun: begun, runPipeline: runPipeline),
        );
  }

  Future<ReadingLiveState> resumeAccelerated({
    required ReadingLiveState begun,
    required Future<String> Function() runPipeline,
  }) {
    final type = begun.snapshot?.readingType;
    if (serverOwnedCompletion &&
        (type == ReadingType.coffee || type == ReadingType.palm)) {
      return Future.value(ReadingLiveState(
        kind: ReadingLiveKind.processing,
        snapshot: begun.snapshot,
      ));
    }
    return _claimAndExecute(
      begun: begun,
      runPipeline: runPipeline,
      eligibilityEstablished: true,
    );
  }

  Future<ReadingLiveState> _claimAndExecute({
    required ReadingLiveState begun,
    required Future<String> Function() runPipeline,
    bool eligibilityEstablished = false,
  }) async {
    final beginSnapshot = begun.snapshot;
    // BATCH 5F: a `waiting` operation whose own wait has already elapsed
    // (recovered after the app was closed past readyAt, or a genuinely
    // zero-wait config) must still be claimable — otherwise no caller
    // anywhere ever re-attempts the claim once eligible, and the
    // operation is stuck in `waiting` forever. Still-counting-down
    // `waiting` stays untouched: it returns immediately, same as before.
    final waitingButEligible =
        beginSnapshot != null &&
        begun.kind == ReadingLiveKind.waiting &&
        beginSnapshot.waitFinished;
    if (beginSnapshot == null ||
        (begun.kind == ReadingLiveKind.waiting &&
            !waitingButEligible &&
            !eligibilityEstablished) ||
        begun.kind == ReadingLiveKind.failed ||
        begun.kind == ReadingLiveKind.ready) {
      return begun;
    }
    final operationId = beginSnapshot.operationId;
    final claim = await flow.claimIfEligible(operationId);
    if (!claim.execute) {
      return ReadingLiveState(
        kind: ReadingLiveKind.processing,
        snapshot: begun.snapshot,
      );
    }
    try {
      final resultId = await ReadingOperationContext.run(
        operationId,
        runPipeline,
      );
      await flow.complete(operationId: operationId, resultId: resultId);
      return ReadingLiveState(
        kind: ReadingLiveKind.ready,
        snapshot: begun.snapshot,
      );
    } catch (error) {
      final classified = error is ReadingRuntimeException ? error : null;
      diagnostics.record(
        ReadingRuntimeDiagnostic(
          feature: beginSnapshot.readingType.name,
          operationId: operationId,
          stage: classified?.stage ?? 'pipeline',
          exceptionType: error.runtimeType.toString(),
          safeMessage: classified?.message ?? error.toString(),
          httpStatus: classified?.status,
          backendCode: classified?.backendCode,
        ),
      );
      final refunded = await flow.failFinal(operationId);
      return ReadingLiveState(
        kind: ReadingLiveKind.failed,
        snapshot: begun.snapshot,
        refunded: refunded,
      );
    }
  }
}
