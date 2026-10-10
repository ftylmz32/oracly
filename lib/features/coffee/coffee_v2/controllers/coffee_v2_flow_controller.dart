/// Coffee V2 guided-capture flow controller (Phase 2C2).
///
/// Owns the UI-only ephemeral state (preview candidate, intro-dismissed,
/// replacing-slot) on top of the Phase 2C1 `CoffeeV2SubmissionController`,
/// and — once all three slots are staged — the post-staging wait/result
/// observation. Deliberately does NOT reuse `CoffeeReadingController`: that
/// class only auto-continues polling a recovered `waiting` operation when a
/// LEGACY single-image pending record matches it, which a V2-staged
/// operation never has. Reusing it here would silently strand a V2
/// operation client-side after one recovery pass. Instead this controller
/// duplicates the small, already-proven subset of that polling logic that
/// applies when completion is entirely server-owned (`serverOwnedCompletion
/// == true`) — see `ReadingFeatureRunner.resume`, which reduces to
/// `flow.recover(...)` in that case regardless of `runPipeline`/
/// `sourceRequestId`, so no local pipeline execution is ever needed here.
///
/// Every leaf rendering widget this controller drives (`CoffeeLoadingView`,
/// `CoffeeResultView`, `CoffeeErrorView`) is reused verbatim from the
/// existing Coffee presentation layer — nothing here is a second
/// loading/result system.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../reading_operation/models/reading_acceleration.dart';
import '../../../reading_operation/models/reading_operation_status.dart';
import '../../../reading_operation/copy/reading_live_copy.dart';
import '../../../reading_operation/services/reading_live_flow.dart';
import '../../models/coffee_image_pick.dart';
import '../../models/coffee_reading.dart';
import '../../services/coffee_experience_service.dart';
import '../models/coffee_v2_flow_stage.dart';
import '../models/coffee_v2_intention.dart';
import '../models/coffee_v2_photo_slot.dart';
import '../models/coffee_v2_stage_state.dart';
import '../models/coffee_v2_submission_record.dart';
import '../services/coffee_v2_submission_controller.dart';
import '../services/coffee_v2_validation.dart';

class CoffeeV2FlowController extends ChangeNotifier {
  CoffeeV2FlowController({
    required this.submission,
    required this.flow,
    required this.experience,
    this.onAuthoritativeBalance,
  });

  final CoffeeV2SubmissionController? submission;
  final ReadingLiveFlow? flow;
  final CoffeeExperienceService experience;
  final Future<void> Function(int balance)? onAuthoritativeBalance;

  bool _disposed = false;
  bool _recovered = false;
  bool _introDismissed = false;
  CoffeeV2PhotoSlot? _replacingSlot;
  CoffeeImagePick? _previewCandidate;
  CoffeeV2PhotoSlot? _previewCandidateSlot;
  CoffeeV2SlotSelectionFailure? lastSelectionFailure;
  CoffeeV2ValidationIssue? lastDuplicateIssue;
  bool _stagingInFlight = false;
  bool stagingRetryable = false;
  String? _sourceRequestId;

  ReadingLiveState? liveState;
  CoffeeReading? reading;
  String? observeError;
  bool accelerating = false;
  String? accelerationError;
  int? accelerationCost;
  String? _accelerationPriceToken;
  String? _accelerationQuotedFor;
  Timer? _resumeTimer;
  int _generation = 0;
  int _readyMisses = 0;
  bool _resultUnfetched = false;

  @override
  void dispose() {
    _disposed = true;
    _resumeTimer?.cancel();
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  bool get available => submission != null && flow != null;
  bool get booted => _recovered;
  bool get introDismissed => _introDismissed;
  bool get stagingInFlight => _stagingInFlight;
  CoffeeV2PhotoSlot? get replacingSlot => _replacingSlot;
  CoffeeImagePick? get previewCandidate => _previewCandidate;
  CoffeeV2PhotoSlot? get previewCandidateSlot => _previewCandidateSlot;

  CoffeeV2SubmissionRecord get record => submission!.record;
  bool get hasValidIntention =>
      canonicalCoffeeV2Intention(record.intention) != null;

  Future<void> selectIntention(CoffeeV2IntentionChoice choice) async {
    if (choice == CoffeeV2IntentionChoice.other) {
      await submission?.setIntention(null);
    } else {
      await submission?.setIntention(choice.intention);
    }
    _notify();
  }

  Future<void> setCustomIntention(String value) async {
    await submission?.setIntention(value);
    _notify();
  }

  bool get _allSlotsStaged =>
      record.isActive &&
      coffeeV2CanonicalSlotOrder.every(
        (slot) => record.slots[slot]?.stageState == CoffeeV2StageState.staged,
      );

  /// Upload data is released only once the operation settled (result
  /// restored or terminal failure). Such a session can never re-stage, so
  /// it must be observed again, not retried as an interrupted upload.
  bool get _terminalHandoffPending =>
      record.isActive &&
      coffeeV2CanonicalSlotOrder.every(
        (slot) => record.slots[slot]?.asset == null,
      );

  CoffeeV2FlowStage get stage {
    if (!_recovered) return CoffeeV2FlowStage.booting;
    if (!available) return CoffeeV2FlowStage.unavailable;
    // A restored result owns presentation even after upload-only draft data
    // has been released. Never fall through to a fresh capture step.
    if (reading != null || observeError != null) {
      return CoffeeV2FlowStage.activeObserving;
    }
    if (record.isActive) {
      return _allSlotsStaged || _terminalHandoffPending
          ? CoffeeV2FlowStage.activeObserving
          : CoffeeV2FlowStage.activeStaging;
    }
    if (_previewCandidate != null) return CoffeeV2FlowStage.preview;
    if (_replacingSlot != null) return CoffeeV2FlowStage.step;
    if (!_introDismissed) return CoffeeV2FlowStage.intro;
    if (submission!.allThreeConfirmed) return CoffeeV2FlowStage.finalReview;
    return CoffeeV2FlowStage.step;
  }

  CoffeeV2PhotoSlot get currentStepSlot {
    final replacing = _replacingSlot;
    if (replacing != null) return replacing;
    for (final slot in coffeeV2CanonicalSlotOrder) {
      if (submission!.record.slots[slot]?.confirmed != true) return slot;
    }
    return coffeeV2CanonicalSlotOrder.last;
  }

  /// Call once, right after construction — restores a persisted draft or
  /// active submission (Phase 2C1 §16/§31) without ever auto-submitting.
  Future<void> boot() async {
    if (!available) {
      _recovered = true;
      _notify();
      return;
    }
    await submission!.recoverDraftOrSubmission();
    if (_disposed) return;
    _sourceRequestId ??= record.sourceRequestId;
    _introDismissed =
        record.isActive ||
        coffeeV2CanonicalSlotOrder.any(
          (slot) => record.slots[slot]?.confirmed == true,
        );
    _recovered = true;
    _notify();
    final persistedResultId = record.resultId;
    if (record.resultPendingAcknowledgement && persistedResultId != null) {
      final saved = experience.savedById(persistedResultId);
      if (saved != null) {
        reading = saved;
        _notify();
        return;
      }
      // The user deleted the restored reading (e.g. Privacy clear); never
      // fetch it back from the server.
      await submission!.acknowledgeTerminalHandoff();
      if (_disposed) return;
      _introDismissed = false;
      _notify();
      return;
    }
    if (record.isActive) {
      if (_allSlotsStaged || _terminalHandoffPending) {
        _startObserving();
      } else {
        // An ACTIVE submission that never finished staging (app killed
        // mid-sequence) must keep making progress on its own — otherwise
        // the user is stuck on a "preparing" spinner forever with nothing
        // ever re-attempting it (spec §16).
        unawaited(retryStaging());
      }
      return;
    }
  }

  void dismissIntro() {
    _introDismissed = true;
    _notify();
  }

  void beginReplacing(CoffeeV2PhotoSlot slot) {
    _replacingSlot = slot;
    _notify();
  }

  /// Backing out of a replacement (no new candidate ever picked) returns
  /// to Final Review with the old confirmed asset untouched.
  void cancelReplacing() {
    _replacingSlot = null;
    _notify();
  }

  void setPreviewCandidate(CoffeeV2PhotoSlot slot, CoffeeImagePick picked) {
    _previewCandidateSlot = slot;
    _previewCandidate = picked;
    lastSelectionFailure = null;
    _notify();
  }

  /// "Tekrar çek" / cancel — discards the ephemeral candidate. The
  /// previously confirmed asset for this slot (if any) was never touched.
  void discardPreviewCandidate() {
    _previewCandidate = null;
    _previewCandidateSlot = null;
    _notify();
  }

  Future<CoffeeV2ConfirmOutcome> confirmCandidate() async {
    final slot = _previewCandidateSlot;
    final candidate = _previewCandidate;
    final sub = submission;
    if (slot == null || candidate == null || sub == null) {
      return CoffeeV2ConfirmOutcome.none;
    }
    // Validate the candidate BEFORE committing anything: a rejected candidate
    // (invalid, or a duplicate of another slot) never touches the slot's
    // previously confirmed photo.
    final result = await sub.prepareSlot(slot, candidate);
    final asset = result.asset;
    if (asset == null) {
      _previewCandidate = null;
      _previewCandidateSlot = null;
      lastSelectionFailure = result.failure;
      _notify();
      return CoffeeV2ConfirmOutcome.invalidPhoto;
    }
    final duplicate = sub.duplicateIssueFor(asset);
    if (duplicate != null) {
      lastDuplicateIssue = duplicate;
      _previewCandidate = null;
      _previewCandidateSlot = null;
      _notify();
      return CoffeeV2ConfirmOutcome.duplicate;
    }
    lastDuplicateIssue = null;
    lastSelectionFailure = null;
    await sub.commitConfirmedSlot(asset);
    _previewCandidate = null;
    _previewCandidateSlot = null;
    final wasReplacing = _replacingSlot != null;
    _replacingSlot = null;
    _notify();
    return wasReplacing
        ? CoffeeV2ConfirmOutcome.committedReturnToReview
        : CoffeeV2ConfirmOutcome.committedAdvance;
  }

  Future<void> beginSubmission() async {
    final sub = submission;
    if (sub == null || sub.validationIssue != null || !hasValidIntention)
      return;
    _stagingInFlight = true;
    stagingRetryable = false;
    _notify();
    _sourceRequestId ??=
        record.sourceRequestId ??
        'coffee-v2-${DateTime.now().microsecondsSinceEpoch}';
    try {
      final outcome = await sub.beginSubmission(_sourceRequestId!);
      if (outcome == CoffeeV2SubmissionOutcome.completedStaging) {
        _startObserving();
      } else {
        stagingRetryable = true;
      }
    } catch (_) {
      // Local durability failure is retryable but must never advance the UI
      // as though the operation binding was safely recorded.
      stagingRetryable = true;
    } finally {
      _stagingInFlight = false;
      _notify();
    }
  }

  Future<void> retryStaging() async {
    final sub = submission;
    if (sub == null) return;
    // A create/binding failure can leave a durable sourceRequestId but no
    // local operationId. Retry through beginSubmission so the backend's
    // createIfAbsent returns the SAME operation instead of inventing one.
    if (!record.isActive) {
      await beginSubmission();
      return;
    }
    _stagingInFlight = true;
    stagingRetryable = false;
    _notify();
    try {
      final outcome = await sub.retrySubmission();
      if (outcome == CoffeeV2SubmissionOutcome.completedStaging) {
        _startObserving();
      } else {
        stagingRetryable = true;
      }
    } catch (_) {
      stagingRetryable = true;
    } finally {
      _stagingInFlight = false;
      _notify();
    }
  }

  /// After a completed reading (ready or terminally failed) the submission
  /// record has already been cleared — reset this controller's own
  /// ephemeral state so the flow lands back on Intro for a fresh draft.
  void resetToFreshDraft() {
    if (_resultUnfetched) {
      // The server finished this reading; only fetching it failed. Retry
      // must fetch it again, never acknowledge it away.
      _resultUnfetched = false;
      observeError = null;
      _readyMisses = 0;
      _notify();
      _startObserving();
      return;
    }
    unawaited(_acknowledgeAndReset());
  }

  Future<void> _acknowledgeAndReset() async {
    await submission?.acknowledgeTerminalHandoff();
    liveState = null;
    reading = null;
    observeError = null;
    _introDismissed = false;
    _notify();
  }

  void _startObserving() {
    if (flow == null) return;
    unawaited(_observe());
  }

  Future<void> _observe() async {
    final f = flow;
    if (f == null || _disposed) return;
    final token = ++_generation;
    final state = await f.recover(ReadingType.coffee);
    await _applyObservedState(token: token, state: state);
  }

  Future<void> _applyObservedState({
    required int token,
    required ReadingLiveState state,
  }) async {
    if (_disposed || token != _generation) return;
    liveState = state;
    switch (state.kind) {
      case ReadingLiveKind.ready:
        _resumeTimer?.cancel();
        final resultId = state.snapshot?.resultId;
        final saved = resultId == null ? null : experience.savedById(resultId);
        if (saved != null) {
          reading = saved;
          _readyMisses = 0;
        } else {
          final operationId = state.snapshot?.operationId;
          final completed = operationId == null
              ? null
              : await flow!.fetchCompletedResult(operationId);
          if (completed != null) {
            try {
              reading = await experience.restoreCompleted(
                resultId: completed.resultId,
                persistedAt: completed.persistedAt,
                result: completed.result,
              );
              _readyMisses = 0;
            } catch (_) {
              // Counted as a miss below; never a frozen spinner.
            }
            if (_disposed || token != _generation) return;
          }
        }
        final restored = reading;
        if (restored == null) {
          _readyMisses += 1;
          if (_readyMisses >= 10) {
            observeError = ReadingLiveCopy.failed;
            _resultUnfetched = true;
            _notify();
            return;
          }
          _scheduleServerPoll(token: token);
          _notify();
          return;
        }
        await submission?.onResultRestored(restored.id);
        _notify();
        return;
      case ReadingLiveKind.failed:
        _resumeTimer?.cancel();
        observeError = state.refunded
            ? ReadingLiveCopy.refunded
            : ReadingLiveCopy.failed;
        await submission?.onTerminalFailure();
      case ReadingLiveKind.waiting:
        final operationId = state.snapshot?.operationId;
        if (operationId != null) {
          unawaited(_refreshAccelerationCost(operationId));
        }
        _scheduleResume(token: token, state: state);
      case ReadingLiveKind.processing:
        _scheduleServerPoll(token: token);
      case ReadingLiveKind.idle:
        if (state.unreachable) _scheduleServerPoll(token: token);
    }
    _notify();
  }

  void _scheduleServerPoll({required int token}) {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(
      const Duration(seconds: 3),
      () => unawaited(_pollOnce(token)),
    );
  }

  void _scheduleResume({required int token, required ReadingLiveState state}) {
    _resumeTimer?.cancel();
    final remaining = state.displayRemaining(Duration.zero);
    final delay = remaining <= Duration.zero
        ? const Duration(seconds: 1)
        : remaining + const Duration(seconds: 1);
    _resumeTimer = Timer(delay, () => unawaited(_pollOnce(token)));
  }

  Future<void> _pollOnce(int token) async {
    if (_disposed || token != _generation) return;
    final state = await flow!.recover(ReadingType.coffee);
    await _applyObservedState(token: token, state: state);
  }

  Future<void> _refreshAccelerationCost(String operationId) async {
    final quote = await flow!.quoteAcceleration(operationId);
    if (_disposed || liveState?.snapshot?.operationId != operationId) return;
    if (quote == null) return;
    _accelerationQuotedFor = operationId;
    accelerationCost = quote.canonicalCost;
    _accelerationPriceToken = quote.priceToken;
    _notify();
  }

  /// Requires a server quote for THIS operation: without its price token the
  /// server would charge whatever it currently costs, unseen by the user.
  bool get canAccelerate {
    final operationId = liveState?.snapshot?.operationId;
    return liveState?.kind == ReadingLiveKind.waiting &&
        !accelerating &&
        operationId != null &&
        _accelerationQuotedFor == operationId &&
        accelerationCost != null &&
        _accelerationPriceToken != null;
  }

  Future<void> accelerateWaiting() async {
    if (!canAccelerate || flow == null) return;
    final operationId = liveState?.snapshot?.operationId;
    if (operationId == null) return;
    accelerating = true;
    accelerationError = null;
    _notify();
    try {
      final result = await flow!.accelerate(
        operationId: operationId,
        idempotencyKey: 'coffee-v2:$operationId:accelerate',
        expectedPriceToken: _accelerationPriceToken,
      );
      final authoritativeBalance = result.balance;
      if (authoritativeBalance != null) {
        await onAuthoritativeBalance?.call(authoritativeBalance);
      }
      if (result.outcome == ReadingAccelerationOutcome.alreadyEligible) {
        accelerationCost = result.canonicalCost;
        _accelerationPriceToken = result.priceToken;
        return;
      }
      if (result.outcome == ReadingAccelerationOutcome.priceChanged) {
        accelerationCost = result.canonicalCost;
        _accelerationPriceToken = result.priceToken;
        accelerationError = ReadingLiveCopy.priceChanged;
        return;
      }
      if (result.outcome == ReadingAccelerationOutcome.insufficientGems) {
        accelerationError = ReadingLiveCopy.insufficient;
        return;
      }
      if (result.outcome == ReadingAccelerationOutcome.reconcile) {
        accelerationError = ReadingLiveCopy.failed;
        return;
      }
      final token = ++_generation;
      final state = await flow!.recover(ReadingType.coffee);
      await _applyObservedState(token: token, state: state);
    } finally {
      accelerating = false;
      _notify();
    }
  }
}
