/// El Falı state machine.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../coffee/models/coffee_image_pick.dart';
import '../../coffee/services/coffee_image_input_port.dart';
import '../../../core/audio/oracly_feedback_gate.dart';
import '../../../core/logging/analysis_debug_log.dart';
import '../copy/palm_copy.dart';
import '../models/palm_analysis_error.dart';
import '../models/palm_hand.dart';
import '../models/palm_reading.dart';
import '../services/palm_experience_service.dart';
import '../services/palm_image_archive.dart';
import '../services/palm_image_intake.dart';
import '../../reading_operation/copy/reading_live_copy.dart';
import '../../reading_operation/models/reading_operation_status.dart';
import '../../reading_operation/models/reading_acceleration.dart';
import '../../reading_operation/services/reading_feature_runner.dart';
import '../../reading_operation/services/reading_live_flow.dart';
import '../../reading_operation/services/reading_pending_operation_store.dart';

part 'palm_reading_controller_capture.dart';
part 'palm_reading_controller_analysis.dart';

enum PalmPhase { entry, capture, analyzing, result, error }

class PalmReadingController extends ChangeNotifier
    with PalmReadingCapture, PalmReadingAnalysis {
  PalmReadingController({
    required PalmExperienceService experience,
    required CoffeeImageInputPort images,
    ReadingFeatureRunner? live,
    ReadingPendingOperationStore? pendingStore,
    Future<void> Function(int balance)? acceptAuthoritativeBalance,
  }) {
    bindCapture(
      experience,
      images,
      live: live,
      pendingStore: pendingStore,
      acceptAuthoritativeBalance: acceptAuthoritativeBalance,
    );
  }

  bool get canAccelerate =>
      liveState?.kind == ReadingLiveKind.waiting && !_accelerating;
  bool get accelerating => _accelerating;
  String? get accelerationError => _accelerationError;

  Future<void> accelerateWaiting() async {
    if (!canAccelerate) return;
    final live = _live;
    final operationId = liveState?.snapshot?.operationId;
    final pending = _pendingStore?.load(ReadingType.palm);
    if (live == null || operationId == null) return;
    _accelerating = true;
    _accelerationError = null;
    safeNotify();
    try {
      final result = await live.flow.accelerate(
        operationId: operationId,
        idempotencyKey: 'palm:$operationId:accelerate',
        expectedPriceToken: _accelerationPriceToken,
      );
      final authoritativeBalance = result.balance;
      if (authoritativeBalance != null) {
        await _acceptAuthoritativeBalance?.call(authoritativeBalance);
      }
      if (result.outcome == ReadingAccelerationOutcome.alreadyEligible) {
        // The free wait was already over server-side -- zero Gems charged,
        // nothing to accelerate. The operation is still exactly `waiting`;
        // do NOT force a fake `processing` state (that would lie about
        // server truth). The existing poll loop (already running since
        // this operation first became `waiting`) keeps observing on its
        // own -- this is not a failure, so no error is shown either.
        _accelerationCost = result.canonicalCost;
        _accelerationPriceToken = result.priceToken;
        return;
      }
      if (result.outcome == ReadingAccelerationOutcome.priceChanged) {
        // Server refused to charge a stale price -- zero debit. Refresh to
        // the fresh cost/token it handed back (no extra round trip) and
        // require a brand-new explicit tap; never retry automatically.
        _accelerationCost = result.canonicalCost;
        _accelerationPriceToken = result.priceToken;
        _accelerationError = ReadingLiveCopy.priceChanged;
        return;
      }
      if (result.outcome == ReadingAccelerationOutcome.insufficientGems) {
        _accelerationError = ReadingLiveCopy.insufficient;
        return;
      }
      if (result.outcome == ReadingAccelerationOutcome.reconcile) {
        _accelerationError = ReadingLiveCopy.failed;
        return;
      }
      final hand = pending?.handSide == PalmHand.left.name
          ? PalmHand.left
          : PalmHand.right;
      PalmReading? captured;
      Future<String> runPipeline() async {
        final reading = await _experience.analyzeStaged(
          operationId: operationId,
          mimeType: pending?.mimeType ?? 'image/jpeg',
          hand: hand,
        );
        captured = reading;
        return reading.id;
      }

      final token = ++_generation;
      final resumed = await live.resumeAccelerated(
        begun: liveState!,
        runPipeline: runPipeline,
      );
      _applyAnalyzeSnapshot(
        token: token,
        live: live,
        source: pending?.sourceRequestId ?? operationId,
        fallbackImagePath: _image?.path ?? '',
        runPipeline: runPipeline,
        capturedReading: () => captured,
        state: resumed,
      );
    } finally {
      _accelerating = false;
      safeNotify();
    }
  }

  @override
  void dispose() {
    markDisposed();
    super.dispose();
  }

  /// BATCH 5F — call on feature open / controller reconstruction so an
  /// active Palm operation (waiting/processing/ready/failed) survives an
  /// app kill+relaunch. Never re-runs AI for an already-ready result and
  /// never starts a new operation.
  ///
  /// For a still-`waiting` operation this is now ACTIVE, not passive: if a
  /// pending-operation record was persisted for the SAME operationId the
  /// server still reports, it attempts to claim+execute via the
  /// staged-only pipeline — the server-held image, never local bytes,
  /// which this fresh controller instance does not have. Without a
  /// matching pending record it only reflects status, as before.
  Future<void> recoverActive() async {
    final live = _live;
    if (live == null) return;
    final pending = _pendingStore?.load(ReadingType.palm);
    final state = await live.flow.recover(ReadingType.palm);
    if (_disposed) return;
    switch (state.kind) {
      case ReadingLiveKind.ready:
        unawaited(_pendingStore?.clear(ReadingType.palm));
        final resultId = state.snapshot?.resultId;
        final saved = resultId == null ? null : _experience.savedById(resultId);
        liveState = state;
        if (saved != null) {
          openSaved(saved);
        } else {
          await _restoreServerCompleted(state, live);
          safeNotify();
        }
      case ReadingLiveKind.waiting:
        liveState = state;
        _phase = PalmPhase.analyzing;
        _error = null;
        final recoveredOperationId = state.snapshot?.operationId;
        if (recoveredOperationId != null) {
          unawaited(refreshAccelerationCost(live, recoveredOperationId));
        }
        if (pending != null &&
            pending.operationId == state.snapshot?.operationId) {
          await _recoverWaiting(pending: pending);
          return;
        }
        safeNotify();
      case ReadingLiveKind.processing:
        liveState = state;
        _phase = PalmPhase.analyzing;
        _error = null;
        _scheduleServerPoll(live);
        safeNotify();
      case ReadingLiveKind.failed:
        unawaited(_pendingStore?.clear(ReadingType.palm));
        liveState = state;
        _error = ReadingLiveCopy.failed;
        _phase = PalmPhase.error;
        safeNotify();
      case ReadingLiveKind.idle:
        break;
    }
  }

  /// Actively resumes a recovered `waiting` operation using ONLY the
  /// server-staged image — reuses the exact same `_applyAnalyzeSnapshot`/
  /// `_scheduleResume`/`_resumeAnalyze` machinery `analyze()` uses, just
  /// with a staged-only `runPipeline` instead of one closed over local
  /// bytes.
  Future<void> _recoverWaiting({
    required ReadingPendingOperation pending,
  }) async {
    final live = _live;
    if (live == null) return;
    final hand = pending.handSide == PalmHand.left.name
        ? PalmHand.left
        : PalmHand.right;
    final token = ++_generation;
    PalmReading? captured;
    Future<String> runPipeline() async {
      final reading = await _experience.analyzeStaged(
        operationId: pending.operationId,
        mimeType: pending.mimeType,
        hand: hand,
      );
      captured = reading;
      return reading.id;
    }

    final resumed = await live.resume(
      readingType: ReadingType.palm,
      sourceRequestId: pending.sourceRequestId,
      runPipeline: runPipeline,
    );
    _applyAnalyzeSnapshot(
      token: token,
      live: live,
      source: pending.sourceRequestId,
      fallbackImagePath: '',
      runPipeline: runPipeline,
      capturedReading: () => captured,
      state: resumed,
    );
  }

  void openSaved(PalmReading reading) {
    final path = reading.imagePath;
    final exists = path != null && File(path).existsSync();
    _reading = exists ? reading : reading.copyWith(clearImagePath: true);
    _image = exists
        ? CoffeeImagePick(path: path, mimeType: 'image/jpeg')
        : null;
    _error = null;
    _lastError = null;
    _phase = PalmPhase.result;
    safeNotify();
  }
}
