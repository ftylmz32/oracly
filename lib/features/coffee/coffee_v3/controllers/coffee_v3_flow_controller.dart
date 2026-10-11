/// Coffee V3 three-photo flow controller. Follows the proven Coffee V2 state
/// machine but owns three V3 slots and is NOT a V2 controller with
/// conditionals. Once an operation is bound it observes that EXACT
/// operation (`ReadingLiveFlow.recoverOperation(operationId)`) for wait /
/// processing / ready / failed / result fetch / acceleration — never the
/// feature-wide `recover(ReadingType.coffee)`, so a V3 session can never
/// attach to another Coffee operation.
///
/// Flags gate NEW creation only: an active V3 operation keeps recovering,
/// polling, accelerating and restoring its result whatever the rollout flag
/// or UI language says. Completion is server-owned; the result is restored
/// through Slice 3 (`m2_public_v1`) and shown by the existing
/// `CoffeeResultView`.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../reading_operation/copy/reading_live_copy.dart';
import '../../../reading_operation/models/reading_acceleration.dart';
import '../../../reading_operation/services/reading_live_flow.dart';
import '../../coffee_v2/models/coffee_v2_intention.dart';
import '../../models/coffee_image_pick.dart';
import '../../models/coffee_reading.dart';
import '../../services/coffee_experience_service.dart';
import '../models/coffee_v3_flow_stage.dart';
import '../models/coffee_v3_photo_slot.dart';
import '../models/coffee_v3_stage_state.dart';
import '../models/coffee_v3_submission_record.dart';
import '../services/coffee_v3_submission_controller.dart';

/// Why the final-review CTA cannot currently create the operation.
enum CoffeeV3CreateBlock {
  /// Client rollout flag off or non-Turkish UI (draft kept, CTA disabled).
  creationDisabled,

  /// Backend refused the three-photo create (draft kept).
  serverUnavailable,

  /// Transport failure before an operation was bound (draft kept).
  connectionLost,
}

class CoffeeV3FlowController extends ChangeNotifier {
  CoffeeV3FlowController({
    required this.submission,
    required this.flow,
    required this.experience,
    this.onAuthoritativeBalance,
  });

  final CoffeeV3SubmissionController? submission;
  final ReadingLiveFlow? flow;
  final CoffeeExperienceService experience;
  final Future<void> Function(int balance)? onAuthoritativeBalance;

  bool _disposed = false;
  bool _recovered = false;
  bool _introDismissed = false;
  CoffeeV3PhotoSlot? _replacingSlot;
  CoffeeImagePick? _previewCandidate;
  CoffeeV3PhotoSlot? _previewCandidateSlot;
  CoffeeV3SlotSelectionFailure? lastSelectionFailure;
  CoffeeV3PhotoSlot? lastDuplicateOf;
  bool _stagingInFlight = false;
  bool stagingRetryable = false;
  CoffeeV3CreateBlock? _lastCreateBlock;

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
  CoffeeV3PhotoSlot? get replacingSlot => _replacingSlot;
  CoffeeImagePick? get previewCandidate => _previewCandidate;
  CoffeeV3PhotoSlot? get previewCandidateSlot => _previewCandidateSlot;

  CoffeeV3SubmissionRecord get record => submission!.record;
  bool get hasValidIntention =>
      canonicalCoffeeV2Intention(record.intention) != null;

  /// The bound V3 operation — the ONLY operation this session observes.
  String? get operationId => record.operationId;

  bool get creationAllowed => submission?.creationAllowed ?? false;

  /// Why the CTA is blocked right now (null = not blocked by availability).
  CoffeeV3CreateBlock? get createBlock {
    if (!creationAllowed) return CoffeeV3CreateBlock.creationDisabled;
    return _lastCreateBlock;
  }

  /// Final-review CTA: three valid unique confirmed photos, a valid
  /// intention, creation currently allowed, not already in flight.
  bool get canSubmit =>
      !_stagingInFlight && (submission?.readyToCreate ?? false);

  /// Local cup hero for staging / waiting (null once temp files released).
  String? get heroPath =>
      submission?.assetFor(CoffeeV3PhotoSlot.cupViewA)?.path;

  Future<void> selectIntention(CoffeeV2IntentionChoice choice) async {
    await submission?.setIntention(
      choice == CoffeeV2IntentionChoice.other ? null : choice.intention,
    );
    _notify();
  }

  Future<void> setCustomIntention(String value) async {
    await submission?.setIntention(value);
    _notify();
  }

  bool get _allSlotsStaged =>
      record.isActive &&
      coffeeV3CanonicalSlotOrder.every(
        (slot) => record.slots[slot]?.stageState == CoffeeV3StageState.staged,
      );

  /// Upload data released after the operation settled; such a session is
  /// observed again, never re-staged.
  bool get _terminalHandoffPending =>
      record.isActive &&
      coffeeV3CanonicalSlotOrder.every(
        (slot) => record.slots[slot]?.asset == null,
      );

  CoffeeV3FlowStage get stage {
    if (!_recovered) return CoffeeV3FlowStage.booting;
    if (!available) return CoffeeV3FlowStage.unavailable;
    if (reading != null || observeError != null) {
      return CoffeeV3FlowStage.activeObserving;
    }
    if (record.isActive) {
      return _allSlotsStaged || _terminalHandoffPending
          ? CoffeeV3FlowStage.activeObserving
          : CoffeeV3FlowStage.activeStaging;
    }
    // A genuinely empty draft may only start while creation is allowed;
    // otherwise hand back to the default (V2) route. A draft with photos is
    // never abandoned — it stays reviewable / replaceable / cancellable.
    if (!creationAllowed && !record.hasAnyAsset && _previewCandidate == null) {
      return CoffeeV3FlowStage.exitToDefault;
    }
    if (_previewCandidate != null) return CoffeeV3FlowStage.preview;
    if (_replacingSlot != null) return CoffeeV3FlowStage.step;
    if (!_introDismissed) return CoffeeV3FlowStage.intro;
    if (submission!.allConfirmed) return CoffeeV3FlowStage.finalReview;
    return CoffeeV3FlowStage.step;
  }

  CoffeeV3PhotoSlot get currentStepSlot {
    final replacing = _replacingSlot;
    if (replacing != null) return replacing;
    for (final slot in coffeeV3CanonicalSlotOrder) {
      if (record.slots[slot]?.confirmed != true) return slot;
    }
    return coffeeV3CanonicalSlotOrder.last;
  }

  /// Restores a persisted V3 draft or active submission; never auto-submits.
  Future<void> boot() async {
    if (!available) {
      _recovered = true;
      _notify();
      return;
    }
    await submission!.recoverDraftOrSubmission();
    if (_disposed) return;
    _introDismissed = record.isActive ||
        coffeeV3CanonicalSlotOrder.any(
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
      // The restored reading was deleted locally; never fetch it back.
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
        // Killed mid-staging: resume the SAME operation from the first
        // unstaged slot.
        unawaited(retryStaging());
      }
    }
  }

  void dismissIntro() {
    _introDismissed = true;
    _notify();
  }

  void beginReplacing(CoffeeV3PhotoSlot slot) {
    if (record.isActive) return;
    _replacingSlot = slot;
    _notify();
  }

  void cancelReplacing() {
    _replacingSlot = null;
    _notify();
  }

  void setPreviewCandidate(CoffeeV3PhotoSlot slot, CoffeeImagePick picked) {
    // Post-create photos are immutable: no candidate on an active session.
    if (record.isActive) return;
    _previewCandidateSlot = slot;
    _previewCandidate = picked;
    lastSelectionFailure = null;
    lastDuplicateOf = null;
    _notify();
  }

  /// "Tekrar çek": drops only the ephemeral candidate.
  void discardPreviewCandidate() {
    _previewCandidate = null;
    _previewCandidateSlot = null;
    _notify();
  }

  Future<CoffeeV3ConfirmOutcome> confirmCandidate() async {
    final slot = _previewCandidateSlot;
    final candidate = _previewCandidate;
    final sub = submission;
    if (slot == null || candidate == null || sub == null || record.isActive) {
      return CoffeeV3ConfirmOutcome.none;
    }
    final result = await sub.selectSlot(slot, candidate);
    _previewCandidate = null;
    _previewCandidateSlot = null;
    if (!result.isSuccess) {
      final duplicate =
          result.failure == CoffeeV3SlotSelectionFailure.duplicate;
      lastSelectionFailure = duplicate ? null : result.failure;
      lastDuplicateOf = duplicate ? result.duplicateOf : null;
      _notify();
      return duplicate
          ? CoffeeV3ConfirmOutcome.duplicate
          : CoffeeV3ConfirmOutcome.invalidPhoto;
    }
    lastSelectionFailure = null;
    lastDuplicateOf = null;
    _lastCreateBlock = null;
    final wasReplacing = _replacingSlot != null;
    _replacingSlot = null;
    _notify();
    return wasReplacing
        ? CoffeeV3ConfirmOutcome.committedReturnToReview
        : CoffeeV3ConfirmOutcome.committedAdvance;
  }

  /// DRAFT only — deletes V3 temp photos and V3 draft metadata.
  Future<void> cancelDraft() async {
    final sub = submission;
    if (sub == null || record.isActive) return;
    await sub.cancelDraft();
    _replacingSlot = null;
    _previewCandidate = null;
    _previewCandidateSlot = null;
    _lastCreateBlock = null;
    _introDismissed = false;
    _notify();
  }

  Future<void> beginSubmission() async {
    final sub = submission;
    if (sub == null || !canSubmit) {
      if (sub != null && !sub.creationAllowed) _notify();
      return;
    }
    _stagingInFlight = true;
    stagingRetryable = false;
    _lastCreateBlock = null;
    _notify();
    try {
      final outcome = await sub.beginSubmission();
      _applySubmissionOutcome(outcome);
    } catch (_) {
      // Local durability failure: retryable, never advance as though the
      // operation binding were safely recorded.
      if (record.isActive) {
        stagingRetryable = true;
      } else {
        _lastCreateBlock = CoffeeV3CreateBlock.connectionLost;
      }
    } finally {
      _stagingInFlight = false;
      _notify();
    }
  }

  void _applySubmissionOutcome(CoffeeV3SubmissionOutcome outcome) {
    switch (outcome) {
      case CoffeeV3SubmissionOutcome.completedStaging:
        _startObserving();
      case CoffeeV3SubmissionOutcome.createRejected:
        _lastCreateBlock = CoffeeV3CreateBlock.serverUnavailable;
      case CoffeeV3SubmissionOutcome.creationDisabled:
        _lastCreateBlock = CoffeeV3CreateBlock.creationDisabled;
      case CoffeeV3SubmissionOutcome.retryableFailure:
        if (record.isActive) {
          stagingRetryable = true;
        } else {
          _lastCreateBlock = CoffeeV3CreateBlock.connectionLost;
        }
      case CoffeeV3SubmissionOutcome.blockedByValidation:
      case CoffeeV3SubmissionOutcome.activeSubmissionInProgress:
      case CoffeeV3SubmissionOutcome.notEligible:
        break;
    }
  }

  /// Retries staging on the SAME bound operation (already-staged slots are
  /// skipped). Without a bound operation it is a create retry, which goes
  /// back through the gated `beginSubmission` with the SAME sourceRequestId.
  Future<void> retryStaging() async {
    final sub = submission;
    if (sub == null) return;
    if (!record.isActive) {
      await beginSubmission();
      return;
    }
    _stagingInFlight = true;
    stagingRetryable = false;
    _notify();
    try {
      final outcome = await sub.retrySubmission();
      if (outcome == CoffeeV3SubmissionOutcome.completedStaging) {
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

  /// New Cup / terminal: acknowledge the handoff and start a clean draft
  /// identity. A result that finished server-side but failed to fetch is
  /// fetched again instead of being acknowledged away.
  void resetToFreshDraft() {
    if (_resultUnfetched) {
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
    _lastCreateBlock = null;
    stagingRetryable = false;
    _notify();
  }

  void _startObserving() {
    if (flow == null || operationId == null) return;
    unawaited(_pollOnce(++_generation));
  }

  Future<ReadingLiveState?> _recoverExact() async {
    final id = operationId;
    if (id == null) return null;
    return flow!.recoverOperation(id);
  }

  Future<void> _pollOnce(int token) async {
    if (_disposed || token != _generation) return;
    final state = await _recoverExact();
    if (state == null) return;
    await _applyObservedState(token: token, state: state);
  }

  Future<void> _applyObservedState({
    required int token,
    required ReadingLiveState state,
  }) async {
    if (_disposed || token != _generation) return;
    final boundId = operationId;
    final snapshotId = state.snapshot?.operationId;
    // Defensive: never adopt a state that belongs to another operation.
    if (snapshotId != null && snapshotId != boundId) {
      _scheduleServerPoll(token: token);
      return;
    }
    liveState = state;
    switch (state.kind) {
      case ReadingLiveKind.ready:
        _resumeTimer?.cancel();
        final resultId = state.snapshot?.resultId;
        final saved = resultId == null ? null : experience.savedById(resultId);
        if (saved != null) {
          reading = saved;
          _readyMisses = 0;
        } else if (boundId != null) {
          final completed = await flow!.fetchCompletedResult(boundId);
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
          }
          if (_disposed || token != _generation) return;
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
        observeError =
            state.refunded ? ReadingLiveCopy.refunded : ReadingLiveCopy.failed;
        await submission?.onTerminalFailure();
      case ReadingLiveKind.waiting:
        if (boundId != null) unawaited(_refreshAccelerationCost(boundId));
        _scheduleResume(token: token, state: state);
      case ReadingLiveKind.processing:
        _scheduleServerPoll(token: token);
      case ReadingLiveKind.idle:
        if (state.unreachable || state.authRejected) {
          _scheduleServerPoll(token: token);
        } else {
          // The exact operation is gone / not ours (404/400): terminal,
          // never an endless spinner and never another operation.
          _resumeTimer?.cancel();
          observeError = ReadingLiveCopy.failed;
          await submission?.onTerminalFailure();
        }
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

  Future<void> _refreshAccelerationCost(String id) async {
    final quote = await flow!.quoteAcceleration(id);
    if (_disposed || operationId != id || quote == null) return;
    _accelerationQuotedFor = id;
    accelerationCost = quote.canonicalCost;
    _accelerationPriceToken = quote.priceToken;
    _notify();
  }

  /// Requires a server quote for THIS operation (its price token), exactly
  /// like Coffee V2. Not gated by the rollout flag: an existing operation
  /// stays acceleratable.
  bool get canAccelerate {
    final id = operationId;
    return liveState?.kind == ReadingLiveKind.waiting &&
        !accelerating &&
        id != null &&
        liveState?.snapshot?.operationId == id &&
        _accelerationQuotedFor == id &&
        accelerationCost != null &&
        _accelerationPriceToken != null;
  }

  Future<void> accelerateWaiting() async {
    if (!canAccelerate || flow == null) return;
    final id = operationId!;
    accelerating = true;
    accelerationError = null;
    _notify();
    try {
      final result = await flow!.accelerate(
        operationId: id,
        idempotencyKey: 'coffee-v3:$id:accelerate',
        expectedPriceToken: _accelerationPriceToken,
      );
      final authoritativeBalance = result.balance;
      if (authoritativeBalance != null) {
        await onAuthoritativeBalance?.call(authoritativeBalance);
      }
      switch (result.outcome) {
        case ReadingAccelerationOutcome.alreadyEligible:
          accelerationCost = result.canonicalCost;
          _accelerationPriceToken = result.priceToken;
          return;
        case ReadingAccelerationOutcome.priceChanged:
          // Never auto-retried: the user must see the new price first.
          accelerationCost = result.canonicalCost;
          _accelerationPriceToken = result.priceToken;
          accelerationError = ReadingLiveCopy.priceChanged;
          return;
        case ReadingAccelerationOutcome.insufficientGems:
          accelerationError = ReadingLiveCopy.insufficient;
          return;
        case ReadingAccelerationOutcome.reconcile:
          accelerationError = ReadingLiveCopy.failed;
          return;
        default:
          break;
      }
      final token = ++_generation;
      final state = await _recoverExact();
      if (state != null) await _applyObservedState(token: token, state: state);
    } finally {
      accelerating = false;
      _notify();
    }
  }
}
