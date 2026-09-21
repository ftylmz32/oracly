/// Kahve Falı state machine.
library;

// ignore_for_file: prefer_initializing_formals, prefer_function_declarations_over_variables

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../core/audio/oracly_feedback_gate.dart';
import '../../../core/logging/analysis_debug_log.dart';
import '../copy/coffee_copy.dart';
import '../models/coffee_image_pick.dart';
import '../models/coffee_reading.dart';
import '../services/coffee_experience_service.dart';
import '../services/coffee_image_input_port.dart';
import '../services/coffee_image_intake.dart';
import '../../reading_operation/copy/reading_live_copy.dart';
import '../../reading_operation/models/reading_operation_status.dart';
import '../../reading_operation/models/reading_acceleration.dart';
import '../../reading_operation/services/reading_feature_runner.dart';
import '../../reading_operation/services/reading_live_flow.dart';
import '../../reading_operation/services/reading_pending_operation_store.dart';

part 'coffee_reading_controller_capture.dart';

enum CoffeePhase { entry, capture, analyzing, result, error }

class CoffeeReadingController extends ChangeNotifier {
  CoffeeReadingController({
    required this._experience,
    required this._images,
    ReadingFeatureRunner? live,
    ReadingPendingOperationStore? pendingStore,
    Future<void> Function(int balance)? acceptAuthoritativeBalance,
    Duration serverPollInterval = const Duration(seconds: 3),
  }) : _live = live,
       _pendingStore = pendingStore,
       _acceptAuthoritativeBalance = acceptAuthoritativeBalance,
       _serverPollInterval = serverPollInterval;

  final CoffeeExperienceService _experience;
  final CoffeeImageInputPort _images;
  final ReadingFeatureRunner? _live;
  // Never image bytes — just enough identity (operationId/sourceRequestId/
  // mimeType) to find and resume the SAME staged operation after an app
  // restart or controller disposal loses this instance's in-memory state.
  // The staged server image, not local bytes, is the durable source once
  // an operation has been staged — see analyzeStaged.
  final ReadingPendingOperationStore? _pendingStore;
  final Future<void> Function(int balance)? _acceptAuthoritativeBalance;
  final Duration _serverPollInterval;
  bool _accelerating = false;
  String? _accelerationError;
  int? _accelerationCost;
  String? _accelerationCostFor;
  String? _accelerationPriceToken;
  ReadingLiveState? liveState;
  bool _disposed = false;

  CoffeePhase _phase = CoffeePhase.entry;
  CoffeeImagePick? _image;
  CoffeeReading? _reading;
  String? _error;
  String? _qualityHint;
  List<CoffeeReading> _history = const [];
  bool _versionAdded = false;
  int _versionReloadToken = 0;
  int _generation = 0;
  Timer? _resumeTimer;

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _resumeTimer?.cancel();
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  CoffeePhase get phase => _phase;
  CoffeeImagePick? get image => _image;
  CoffeeReading? get reading => _reading;
  String? get errorMessage => _error;
  String? get qualityHint => _qualityHint;
  List<CoffeeReading> get history => _history;
  bool get lastVersionAdded => _versionAdded;
  int get versionReloadToken => _versionReloadToken;
  CoffeeImageInputPort get images => _images;
  bool get analysisAvailable => _experience.analysisAvailable;
  bool get accelerating => _accelerating;
  bool get canAccelerate =>
      liveState?.kind == ReadingLiveKind.waiting && !_accelerating;
  String? get accelerationError => _accelerationError;

  /// Server-quoted Gem cost for THIS operation. Null until fetched (or if
  /// the fetch fails) -- never a locally invented fallback number.
  int? get accelerationCost => _accelerationCost;

  Future<void> _refreshAccelerationCost(
    ReadingFeatureRunner live,
    String operationId,
  ) async {
    if (_accelerationCostFor == operationId && _accelerationCost != null) {
      return;
    }
    final quote = await live.flow.quoteAcceleration(operationId);
    if (_disposed || liveState?.snapshot?.operationId != operationId) return;
    if (quote == null) return;
    _accelerationCostFor = operationId;
    _accelerationCost = quote.canonicalCost;
    _accelerationPriceToken = quote.priceToken;
    _safeNotify();
  }

  Future<void> accelerateWaiting() async {
    if (!canAccelerate) return;
    final live = _live;
    final operationId = liveState?.snapshot?.operationId;
    final pending = _pendingStore?.load(ReadingType.coffee);
    if (live == null || operationId == null) return;
    _accelerating = true;
    _accelerationError = null;
    _safeNotify();
    try {
      final result = await live.flow.accelerate(
        operationId: operationId,
        idempotencyKey: 'coffee:$operationId:accelerate',
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
      CoffeeReading? captured;
      Future<String> runPipeline() async {
        final reading = await _experience.analyzeStaged(
          operationId: operationId,
          mimeType: pending?.mimeType ?? 'image/jpeg',
        );
        captured = reading;
        return reading.id;
      }

      final token = ++_generation;
      final resumed = await live.resumeAccelerated(
        begun: liveState!,
        runPipeline: runPipeline,
      );
      await _applyLiveState(
        token: token,
        live: live,
        source: pending?.sourceRequestId ?? operationId,
        runPipeline: runPipeline,
        state: resumed,
        capturedReading: () => captured,
      );
    } finally {
      _accelerating = false;
      _safeNotify();
    }
  }

  Future<void> _analyzeLive() async {
    if (_phase == CoffeePhase.analyzing) return;
    final image = _image;
    final live = _live;
    if (image == null || live == null) {
      _error = CoffeeCopy.imageRequired;
      _safeNotify();
      return;
    }
    final token = ++_generation;
    _phase = CoffeePhase.analyzing;
    _error = null;
    _safeNotify();
    final cleaned = image.path.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    final tail = cleaned.length >= 12
        ? cleaned.substring(cleaned.length - 12)
        : cleaned;
    // BATCH 5F: fold the per-attempt token in right after the fixed
    // prefix (never truncated away by the substring below) so a retry
    // after a terminal failure gets a genuinely new operation — a failed
    // operation can never later transition to ready, so reusing its
    // sourceRequestId would permanently block any retry from succeeding.
    final tokenPart = token.toRadixString(36).padLeft(4, '0');
    final source = ('coffee$tokenPart$tail').padRight(16, '0').substring(0, 16);
    CoffeeReading? captured;
    Future<String> runPipeline() async {
      final reading = await _experience.analyze(image);
      captured = reading;
      return reading.id;
    }

    final mimeType = image.mimeType ?? 'image/jpeg';
    final stagedBytes = await File(image.path).readAsBytes();
    final state = await live.submit(
      readingType: ReadingType.coffee,
      sourceRequestId: source,
      imageBytes: stagedBytes,
      mimeType: mimeType,
      runPipeline: runPipeline,
    );
    final stagedOperationId = state.snapshot?.operationId;
    if (state.kind == ReadingLiveKind.waiting && stagedOperationId != null) {
      // Staging already succeeded server-side. The local pointer is useful
      // metadata, but never the authority. Observe its bool result so a
      // false-returning SharedPreferences write is not mistaken for durable
      // success; recovery below can still converge from server active state.
      await _pendingStore?.save(
        ReadingType.coffee,
        ReadingPendingOperation(
          operationId: stagedOperationId,
          sourceRequestId: source,
          mimeType: mimeType,
        ),
      );
    }
    await _applyLiveState(
      token: token,
      live: live,
      source: source,
      runPipeline: runPipeline,
      state: state,
      capturedReading: () => captured,
    );
  }

  /// Applies a `ReadingFeatureRunner` result and, when the operation is
  /// still on its own server-owned wait, schedules exactly one automatic
  /// resume attempt for when that wait elapses.
  ///
  /// This is the missing other half of create -> stage -> [claim +
  /// execute]: `submit` only ever attempts the claim once, at creation
  /// time — for Coffee (a real, non-zero wait by design), that attempt is
  /// virtually always too early, and nothing previously ever re-attempted
  /// it, so a legitimately-eligible-later operation could sit `waiting`
  /// forever from the client's point of view even though the server would
  /// happily claim it. This does not shorten or bypass the wait — it only
  /// ensures the client actually comes back once the wait the server
  /// already computed is over.
  Future<void> _applyLiveState({
    required int token,
    required ReadingFeatureRunner live,
    required String source,
    required Future<String> Function() runPipeline,
    required ReadingLiveState state,
    required CoffeeReading? Function() capturedReading,
  }) async {
    // A stale/cancelled call must never apply its result — matching the
    // guarantee the removed direct-AI path already gave callers.
    if (_disposed || token != _generation) return;
    liveState = state;
    switch (state.kind) {
      case ReadingLiveKind.ready:
        _resumeTimer?.cancel();
        unawaited(_pendingStore?.clear(ReadingType.coffee));
        final captured = capturedReading();
        if (captured != null) {
          _reading = captured;
          _phase = CoffeePhase.result;
        } else {
          // A different claimant (another instance/session) executed this
          // operation — reload its persisted result rather than leaving a
          // stale spinner up.
          final resultId = state.snapshot?.resultId;
          final saved = resultId == null
              ? null
              : _experience.savedById(resultId);
          if (saved != null) {
            _reading = saved;
            _phase = CoffeePhase.result;
          } else if (resultId != null) {
            final completed = await live.flow.fetchCompletedResult(
              state.snapshot!.operationId,
            );
            if (completed != null) {
              _reading = await _experience.restoreCompleted(
                resultId: completed.resultId,
                persistedAt: completed.persistedAt,
                result: completed.result,
              );
              _phase = CoffeePhase.result;
            }
          }
        }
        _safeNotify();
        if (_phase == CoffeePhase.result) await loadHistory();
        return;
      case ReadingLiveKind.failed:
        _resumeTimer?.cancel();
        unawaited(_pendingStore?.clear(ReadingType.coffee));
        _error = state.refunded
            ? ReadingLiveCopy.refunded
            : ReadingLiveCopy.failed;
        _phase = CoffeePhase.error;
      case ReadingLiveKind.waiting:
        _phase = CoffeePhase.analyzing;
        final waitingOperationId = state.snapshot?.operationId;
        if (waitingOperationId != null) {
          unawaited(_refreshAccelerationCost(live, waitingOperationId));
        }
        _scheduleResume(
          token: token,
          live: live,
          source: source,
          runPipeline: runPipeline,
          capturedReading: capturedReading,
          state: state,
        );
      case ReadingLiveKind.processing:
        _scheduleServerPoll(token: token, live: live);
      case ReadingLiveKind.idle:
        _phase = CoffeePhase.analyzing;
    }
    _safeNotify();
  }

  void _scheduleServerPoll({
    required int token,
    required ReadingFeatureRunner live,
  }) {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(
      _serverPollInterval,
      () => unawaited(() async {
        if (_disposed || token != _generation) return;
        final state = await live.flow.recover(ReadingType.coffee);
        await _applyLiveState(
          token: token,
          live: live,
          source: state.snapshot?.operationId ?? '',
          runPipeline: () async => '',
          state: state,
          capturedReading: () => null,
        );
      }()),
    );
  }

  void _scheduleResume({
    required int token,
    required ReadingFeatureRunner live,
    required String source,
    required Future<String> Function() runPipeline,
    required CoffeeReading? Function() capturedReading,
    required ReadingLiveState state,
  }) {
    _resumeTimer?.cancel();
    final remaining = state.displayRemaining(Duration.zero);
    // Server state is the only authority on failure. Cloud Tasks queue
    // concurrency, cold starts, and backoff can legitimately keep a healthy
    // operation `waiting` well past its own readyAt -- a client-side retry
    // count or elapsed-time heuristic must never infer a terminal failure
    // from that alone. Keep observing indefinitely; the UI distinguishes
    // "counting down" from "overdue, about to be picked up" (see
    // ReadingWaitScreen), never a false error.
    //
    // A small buffer so the retry lands just after, never a beat before,
    // the server's own readyAt — avoids a first attempt guaranteed to lose.
    final delay = remaining <= Duration.zero
        ? const Duration(seconds: 1)
        : remaining + const Duration(seconds: 1);
    _resumeTimer = Timer(
      delay,
      () => unawaited(
        _resume(
          token: token,
          live: live,
          source: source,
          runPipeline: runPipeline,
          capturedReading: capturedReading,
        ),
      ),
    );
  }

  Future<void> _resume({
    required int token,
    required ReadingFeatureRunner live,
    required String source,
    required Future<String> Function() runPipeline,
    required CoffeeReading? Function() capturedReading,
  }) async {
    if (_disposed || token != _generation) return;
    final state = await live.resume(
      readingType: ReadingType.coffee,
      sourceRequestId: source,
      runPipeline: runPipeline,
    );
    await _applyLiveState(
      token: token,
      live: live,
      source: source,
      runPipeline: runPipeline,
      state: state,
      capturedReading: capturedReading,
    );
  }

  Future<void> loadHistory() async {
    _history = _experience.history();
    _safeNotify();
  }

  /// Completion deep-link/push recovery for one exact server operation.
  /// Never falls back to the feature-wide active operation, so a tap for
  /// operation A cannot accidentally open operation B.
  Future<void> recoverOperation(String operationId) async {
    final normalized = operationId.trim();
    final live = _live;
    if (normalized.isEmpty || live == null) return;
    final token = ++_generation;
    await _recoverOperationById(
      token: token,
      live: live,
      operationId: normalized,
    );
  }

  Future<void> _recoverOperationById({
    required int token,
    required ReadingFeatureRunner live,
    required String operationId,
  }) async {
    final state = await live.flow.recoverOperation(operationId);
    if (_disposed || token != _generation) return;
    final snapshot = state.snapshot;
    if (snapshot == null || snapshot.readingType != ReadingType.coffee) return;

    liveState = state;
    switch (state.kind) {
      case ReadingLiveKind.ready:
        final pending = _pendingStore?.load(ReadingType.coffee);
        if (pending?.operationId == operationId) {
          unawaited(_pendingStore?.clear(ReadingType.coffee));
        }
        final resultId = snapshot.resultId;
        final saved = resultId == null ? null : _experience.savedById(resultId);
        if (saved != null) {
          openSaved(saved);
          // openSaved() intentionally clears generic live state for history
          // opens. Exact completion recovery must retain the operation that
          // authenticated this deep-link target.
          liveState = state;
          return;
        }
        final completed = await live.flow.fetchCompletedResult(operationId);
        if (_disposed || token != _generation || completed == null) return;
        final restored = await _experience.restoreCompleted(
          resultId: completed.resultId,
          persistedAt: completed.persistedAt,
          result: completed.result,
        );
        if (_disposed || token != _generation) return;
        openSaved(restored);
        liveState = state;
      case ReadingLiveKind.waiting:
      case ReadingLiveKind.processing:
        _phase = CoffeePhase.analyzing;
        _error = null;
        _scheduleTargetOperationPoll(
          token: token,
          live: live,
          operationId: operationId,
        );
        _safeNotify();
      case ReadingLiveKind.failed:
        _error = ReadingLiveCopy.failed;
        _phase = CoffeePhase.error;
        _safeNotify();
      case ReadingLiveKind.idle:
        break;
    }
  }

  void _scheduleTargetOperationPoll({
    required int token,
    required ReadingFeatureRunner live,
    required String operationId,
  }) {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(
      _serverPollInterval,
      () => unawaited(
        _recoverOperationById(
          token: token,
          live: live,
          operationId: operationId,
        ),
      ),
    );
  }

  /// BATCH 5F — call on feature open / controller reconstruction so an
  /// active Coffee operation (waiting/processing/ready/failed) survives an
  /// app kill+relaunch. Never re-runs AI for an already-ready result and
  /// never starts a new operation.
  ///
  /// For a still-`waiting` operation this is now ACTIVE, not passive: if a
  /// pending-operation record was persisted (see `_analyzeLive`) for the
  /// SAME operationId the server still reports, it attempts to
  /// claim+execute via the staged-only pipeline — the server-held image,
  /// never local bytes, which this fresh controller instance does not
  /// have. Without a matching pending record (e.g. an operation from
  /// before this recovery mechanism existed) it only reflects status, as
  /// before — there is nothing safe to resume without that identity.
  Future<void> recoverActive() async {
    final live = _live;
    if (live == null) return;
    final token = _generation;
    final pending = _pendingStore?.load(ReadingType.coffee);
    final state = await live.flow.recover(ReadingType.coffee);
    if (_disposed || token != _generation) return;
    switch (state.kind) {
      case ReadingLiveKind.ready:
        unawaited(_pendingStore?.clear(ReadingType.coffee));
        final resultId = state.snapshot?.resultId;
        final saved = resultId == null ? null : _experience.savedById(resultId);
        liveState = state;
        if (saved != null) {
          openSaved(saved);
        } else {
          final operationId = state.snapshot?.operationId;
          final completed = operationId == null
              ? null
              : await live.flow.fetchCompletedResult(operationId);
          if (completed != null) {
            openSaved(
              await _experience.restoreCompleted(
                resultId: completed.resultId,
                persistedAt: completed.persistedAt,
                result: completed.result,
              ),
            );
          } else {
            _safeNotify();
          }
        }
      case ReadingLiveKind.waiting:
        liveState = state;
        _phase = CoffeePhase.analyzing;
        _error = null;
        final recoveredOperationId = state.snapshot?.operationId;
        if (recoveredOperationId != null) {
          unawaited(_refreshAccelerationCost(live, recoveredOperationId));
        }
        if (pending != null &&
            pending.operationId == state.snapshot?.operationId) {
          await _recoverWaiting(pending: pending);
          return;
        }
        // Server-owned Coffee completion must not depend on SharedPreferences.
        // If the pointer was never written (false-return, old build, storage
        // loss), keep polling the authoritative active operation instead of
        // leaving the user on an endless analyzing screen.
        _scheduleServerPoll(token: _generation, live: live);
        _safeNotify();
      case ReadingLiveKind.processing:
        liveState = state;
        _phase = CoffeePhase.analyzing;
        _error = null;
        _scheduleServerPoll(token: _generation, live: live);
        _safeNotify();
      case ReadingLiveKind.failed:
        unawaited(_pendingStore?.clear(ReadingType.coffee));
        liveState = state;
        _error = ReadingLiveCopy.failed;
        _phase = CoffeePhase.error;
        _safeNotify();
      case ReadingLiveKind.idle:
        break;
    }
  }

  /// Actively resumes a recovered `waiting` operation using ONLY the
  /// server-staged image — reuses the exact same `_applyLiveState`/
  /// `_scheduleResume`/`_resume` machinery `_analyzeLive` uses, just with
  /// a staged-only `runPipeline` instead of one closed over local bytes.
  Future<void> _recoverWaiting({
    required ReadingPendingOperation pending,
  }) async {
    final live = _live;
    if (live == null) return;
    final token = ++_generation;
    CoffeeReading? captured;
    Future<String> runPipeline() async {
      final reading = await _experience.analyzeStaged(
        operationId: pending.operationId,
        mimeType: pending.mimeType,
      );
      captured = reading;
      return reading.id;
    }

    final resumed = await live.resume(
      readingType: ReadingType.coffee,
      sourceRequestId: pending.sourceRequestId,
      runPipeline: runPipeline,
    );
    await _applyLiveState(
      token: token,
      live: live,
      source: pending.sourceRequestId,
      runPipeline: runPipeline,
      state: resumed,
      capturedReading: () => captured,
    );
  }

  String? get liveSubtitle {
    final state = liveState;
    if (state != null && state.kind == ReadingLiveKind.waiting) {
      return ReadingLiveCopy.countdown(state.displayRemaining(Duration.zero));
    }
    if (state?.kind == ReadingLiveKind.processing)
      return ReadingLiveCopy.processing;
    if (state?.refunded == true) return ReadingLiveCopy.refunded;
    return null;
  }

  Future<void> analyze() async {
    if (_phase == CoffeePhase.analyzing) return;
    if (_image == null) {
      _error = CoffeeCopy.imageRequired;
      _safeNotify();
      return;
    }
    if (_live == null) {
      // BATCH 5F: no live direct-AI bypass. Without a ReadingOperation
      // runner (e.g. proxy not configured for this build), fail closed
      // with a typed recoverable state instead of calling AI directly.
      _error = CoffeeCopy.analysisUnavailable;
      _phase = CoffeePhase.error;
      _safeNotify();
      return;
    }
    await _analyzeLive();
  }

  Future<void> reinterpret() async {
    if (_phase == CoffeePhase.analyzing) return;
    final current = _reading;
    final image = _image;
    final live = _live;
    if (current == null || image == null) {
      throw StateError('coffee reinterpret failed');
    }
    if (live == null) {
      // BATCH 5F: no live direct-AI bypass — fail closed the same way
      // analyze() does, rather than silently reinterpreting outside the
      // ReadingOperation runner.
      _error = CoffeeCopy.analysisUnavailable;
      _phase = CoffeePhase.error;
      _safeNotify();
      throw StateError('coffee reinterpret failed');
    }
    final token = ++_generation;
    _phase = CoffeePhase.analyzing;
    _error = null;
    _safeNotify();
    final cleaned = current.id.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    final tail = cleaned.length >= 12
        ? cleaned.substring(cleaned.length - 12)
        : cleaned;
    final tokenPart = token.toRadixString(36).padLeft(4, '0');
    final source = ('re$tokenPart$tail').padRight(16, '0').substring(0, 16);
    CoffeeReinterpretResult? captured;
    try {
      final stagedBytes = await File(image.path).readAsBytes();
      final state = await live.submit(
        readingType: ReadingType.coffee,
        sourceRequestId: source,
        imageBytes: stagedBytes,
        mimeType: image.mimeType ?? 'image/jpeg',
        runPipeline: () async {
          final result = await _experience.reinterpret(
            current: current,
            image: image,
          );
          captured = result;
          return result.reading.id;
        },
      );
      // A stale/cancelled call must never apply its result.
      if (_disposed || token != _generation) return;
      liveState = state;
      if (state.kind == ReadingLiveKind.ready && captured != null) {
        // Reading metadata is authoritative even when version enrichment
        // failed — versionAdded only gates history UI reload.
        _reading = captured!.reading;
        _versionAdded = captured!.versionAdded;
        if (captured!.versionAdded) {
          _versionReloadToken++;
        }
        _phase = CoffeePhase.result;
        OraclyFeedbackGate.successfulAnalysis();
      } else if (state.kind == ReadingLiveKind.failed) {
        _error = state.refunded
            ? ReadingLiveCopy.refunded
            : ReadingLiveCopy.failed;
        _phase = CoffeePhase.error;
      } else {
        _phase = CoffeePhase.analyzing;
      }
    } catch (error) {
      if (_disposed || token != _generation) return;
      logAnalysisFailure(
        feature: 'CoffeeAnalysis',
        stage: 'reinterpret',
        error: error,
      );
      _error = CoffeeCopy.analysisFailed;
      _phase = CoffeePhase.error;
    }
    _safeNotify();
    if (_disposed || token != _generation) return;
    if (_phase != CoffeePhase.result) {
      throw StateError('coffee reinterpret failed');
    }
  }

  void openSaved(CoffeeReading reading) {
    if (_disposed) return;
    _generation++;
    _resumeTimer?.cancel();
    liveState = null;
    _accelerating = false;
    _accelerationError = null;
    _accelerationCost = null;
    _accelerationCostFor = null;
    _accelerationPriceToken = null;
    final path = reading.imagePath;
    final exists = path != null && File(path).existsSync();
    _reading = exists
        ? reading
        : CoffeeReading(
            id: reading.id,
            createdAt: reading.createdAt,
            overall: reading.overall,
            love: reading.love,
            career: reading.career,
            money: reading.money,
            nearFuture: reading.nearFuture,
            takeaway: reading.takeaway,
            visualObservation: reading.visualObservation,
            symbols: reading.symbols,
          );
    _image = exists ? CoffeeImagePick(path: path) : null;
    _error = null;
    _phase = CoffeePhase.result;
    _safeNotify();
  }
}
