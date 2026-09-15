part of 'palm_reading_controller.dart';

mixin PalmReadingAnalysis on PalmReadingCapture {
  Future<void> analyze() async {
    if (_phase == PalmPhase.analyzing) return;
    final image = _image;
    if (image == null) {
      _lastError = PalmAnalysisError(
        PalmAnalysisErrorKind.missingImage,
        PalmCopy.imageRequired,
      );
      _error = PalmCopy.imageRequired;
      safeNotify();
      return;
    }
    final live = _live;
    if (live == null) {
      // BATCH 5F: no live direct-AI bypass. Without a ReadingOperation
      // runner (e.g. proxy not configured for this build), fail closed
      // with a typed recoverable state instead of calling AI directly.
      _setAnalysisError(
        'analyze',
        PalmAnalysisError(
          PalmAnalysisErrorKind.unavailable,
          PalmCopy.analysisUnavailable,
        ),
        'reading_operation_unavailable',
      );
      safeNotify();
      return;
    }
    final token = ++_generation;
    _phase = PalmPhase.analyzing;
    _error = null;
    _lastError = null;
    safeNotify();
    final cleaned = image.path.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    final tail = cleaned.length >= 12 ? cleaned.substring(cleaned.length - 12) : cleaned;
    // A retry after a terminal failure must get a fresh operation — a
    // failed operation can never later transition to ready.
    final tokenPart = token.toRadixString(36).padLeft(4, '0');
    final source = ('palm$tokenPart$tail').padRight(16, '0').substring(0, 16);
    PalmReading? captured;
    Future<String> runPipeline() async {
      final reading = await _experience.analyze(image, hand: _hand);
      captured = reading;
      return reading.id;
    }

    final mimeType = image.mimeType ?? 'image/jpeg';
    final stagedBytes = await File(image.path).readAsBytes();
    final state = await live.submit(
      readingType: ReadingType.palm,
      sourceRequestId: source,
      imageBytes: stagedBytes,
      mimeType: mimeType,
      handSide: _hand.name,
      runPipeline: runPipeline,
    );
    final stagedOperationId = state.snapshot?.operationId;
    if (state.kind == ReadingLiveKind.waiting && stagedOperationId != null) {
      // Staging already happened inside submit() by this point — persist
      // the operation's identity (never bytes) so recoverActive() can
      // find and resume this SAME operation even if this controller
      // instance never sees another tick (app kill, not just dispose).
      unawaited(_pendingStore?.save(
        ReadingType.palm,
        ReadingPendingOperation(
          operationId: stagedOperationId,
          sourceRequestId: source,
          mimeType: mimeType,
          handSide: _hand.name,
        ),
      ));
    }
    if (_disposed || token != _generation) return;
    _applyAnalyzeSnapshot(
      token: token,
      live: live,
      source: source,
      fallbackImagePath: image.path,
      runPipeline: runPipeline,
      capturedReading: () => captured,
      state: state,
    );
  }

  /// Applies an `analyze()`/`resume` result and, when the operation is
  /// still on its own server-owned wait, schedules exactly one automatic
  /// resume attempt for when that wait elapses — mirrors
  /// CoffeeReadingController's `_applyLiveState`. `submit` only ever
  /// attempts the claim once, at creation time; for a real, non-zero wait
  /// that attempt is virtually always too early, and nothing previously
  /// ever re-attempted it, so a legitimately-eligible-later operation
  /// could sit `waiting` forever from the client's point of view.
  void _applyAnalyzeSnapshot({
    required int token,
    required ReadingFeatureRunner live,
    required String source,
    required String fallbackImagePath,
    required Future<String> Function() runPipeline,
    required PalmReading? Function() capturedReading,
    required ReadingLiveState state,
  }) {
    liveState = state;
    switch (state.kind) {
      case ReadingLiveKind.ready:
        _resumeTimer?.cancel();
        unawaited(_pendingStore?.clear(ReadingType.palm));
        final captured = capturedReading();
        if (captured != null) {
          _reading = captured;
          // A staged-only resume (no local bytes available) never sets
          // imagePath — leave _image null rather than fabricate an empty
          // path; a normal in-session run always has a real local path.
          final path = captured.imagePath ?? fallbackImagePath;
          _image = path.isEmpty ? null : CoffeeImagePick(path: path, mimeType: 'image/jpeg');
          _phase = PalmPhase.result;
          OraclyFeedbackGate.successfulAnalysis();
        } else {
          // A different claimant (another instance/session) executed this
          // operation — reload its persisted result rather than leaving a
          // stale spinner up.
          final resultId = state.snapshot?.resultId;
          final saved = resultId == null ? null : _experience.savedById(resultId);
          if (saved != null) {
            final path = saved.imagePath;
            final exists = path != null && File(path).existsSync();
            _reading = exists ? saved : saved.copyWith(clearImagePath: true);
            _image = exists ? CoffeeImagePick(path: path, mimeType: 'image/jpeg') : null;
            _phase = PalmPhase.result;
          } else {
            unawaited(_restoreServerCompleted(state, live));
          }
        }
      case ReadingLiveKind.failed:
        _resumeTimer?.cancel();
        unawaited(_pendingStore?.clear(ReadingType.palm));
        _setAnalysisError(
          'analyze',
          PalmAnalysisError(
            PalmAnalysisErrorKind.unknown,
            state.refunded ? ReadingLiveCopy.refunded : ReadingLiveCopy.failed,
          ),
          'reading_operation_failed',
        );
      case ReadingLiveKind.waiting:
        _phase = PalmPhase.analyzing;
        final waitingOperationId = state.snapshot?.operationId;
        if (waitingOperationId != null) {
          unawaited(refreshAccelerationCost(live, waitingOperationId));
        }
        _scheduleResume(
          token: token,
          live: live,
          source: source,
          fallbackImagePath: fallbackImagePath,
          runPipeline: runPipeline,
          capturedReading: capturedReading,
          state: state,
        );
      case ReadingLiveKind.processing:
        _scheduleServerPoll(live);
      case ReadingLiveKind.idle:
        _phase = PalmPhase.analyzing;
    }
    safeNotify();
  }

  void _scheduleServerPoll(ReadingFeatureRunner live) {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(seconds: 3), () => unawaited(() async {
      if (_disposed) return;
      final state = await live.flow.recover(ReadingType.palm);
      if (_disposed) return;
      _applyAnalyzeSnapshot(
        token: _generation,
        live: live,
        source: state.snapshot?.operationId ?? '',
        fallbackImagePath: '',
        runPipeline: () async => '',
        capturedReading: () => null,
        state: state,
      );
    }()));
  }

  Future<void> _restoreServerCompleted(
    ReadingLiveState state,
    ReadingFeatureRunner live,
  ) async {
    final operationId = state.snapshot?.operationId;
    if (operationId == null) return;
    final completed = await live.flow.fetchCompletedResult(operationId);
    if (completed == null || _disposed) return;
    final hand = completed.result['_handSide'] == PalmHand.left.name
        ? PalmHand.left
        : PalmHand.right;
    final reading = await _experience.restoreCompleted(
      resultId: completed.resultId,
      persistedAt: completed.persistedAt,
      hand: hand,
      result: completed.result,
    );
    if (_disposed) return;
    _reading = reading;
    _image = null;
    _error = null;
    _lastError = null;
    _phase = PalmPhase.result;
    safeNotify();
  }

  void _scheduleResume({
    required int token,
    required ReadingFeatureRunner live,
    required String source,
    required String fallbackImagePath,
    required Future<String> Function() runPipeline,
    required PalmReading? Function() capturedReading,
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
      () => unawaited(_resumeAnalyze(
        token: token,
        live: live,
        source: source,
        fallbackImagePath: fallbackImagePath,
        runPipeline: runPipeline,
        capturedReading: capturedReading,
      )),
    );
  }

  Future<void> _resumeAnalyze({
    required int token,
    required ReadingFeatureRunner live,
    required String source,
    required String fallbackImagePath,
    required Future<String> Function() runPipeline,
    required PalmReading? Function() capturedReading,
  }) async {
    if (_disposed || token != _generation) return;
    final state = await live.resume(
      readingType: ReadingType.palm,
      sourceRequestId: source,
      runPipeline: runPipeline,
    );
    if (_disposed || token != _generation) return;
    _applyAnalyzeSnapshot(
      token: token,
      live: live,
      source: source,
      fallbackImagePath: fallbackImagePath,
      runPipeline: runPipeline,
      capturedReading: capturedReading,
      state: state,
    );
  }

  Future<void> reinterpret() async {
    if (_phase == PalmPhase.analyzing) return;
    final current = _reading;
    final image = _image;
    if (current == null || image == null) {
      throw StateError('palm reinterpret failed');
    }
    final live = _live;
    if (live == null) {
      // BATCH 5F: no live direct-AI bypass — fail closed the same way
      // analyze() does.
      _setAnalysisError(
        'reinterpret',
        PalmAnalysisError(
          PalmAnalysisErrorKind.unavailable,
          PalmCopy.analysisUnavailable,
        ),
        'reading_operation_unavailable',
      );
      safeNotify();
      throw StateError('palm reinterpret failed');
    }
    final token = ++_generation;
    _phase = PalmPhase.analyzing;
    _error = null;
    _lastError = null;
    safeNotify();
    final cleaned = current.id.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    final tail = cleaned.length >= 12 ? cleaned.substring(cleaned.length - 12) : cleaned;
    final tokenPart = token.toRadixString(36).padLeft(4, '0');
    final source = ('repalm$tokenPart$tail').padRight(16, '0').substring(0, 16);
    PalmReinterpretResult? captured;
    final stagedBytes = await File(image.path).readAsBytes();
    final state = await live.submit(
      readingType: ReadingType.palm,
      sourceRequestId: source,
      imageBytes: stagedBytes,
      mimeType: image.mimeType ?? 'image/jpeg',
      handSide: _hand.name,
      runPipeline: () async {
        final result = await _experience.reinterpret(
          current: current,
          image: image,
          hand: _hand,
        );
        captured = result;
        return result.reading.id;
      },
    );
    if (_disposed || token != _generation) return;
    liveState = state;
    if (state.kind == ReadingLiveKind.ready && captured != null) {
      _versionAdded = captured!.versionAdded;
      if (captured!.versionAdded) {
        _reading = captured!.reading;
        _versionReloadToken++;
      }
      _phase = PalmPhase.result;
      OraclyFeedbackGate.successfulAnalysis();
    } else if (state.kind == ReadingLiveKind.failed) {
      _setAnalysisError(
        'reinterpret',
        PalmAnalysisError(
          PalmAnalysisErrorKind.unknown,
          state.refunded ? ReadingLiveCopy.refunded : ReadingLiveCopy.failed,
        ),
        'reading_operation_failed',
      );
    } else {
      _phase = PalmPhase.analyzing;
    }
    safeNotify();
    if (_phase != PalmPhase.result) {
      throw StateError('palm reinterpret failed');
    }
  }

  Future<void> retryAnalysis() async {
    final path = _image?.path;
    if (path != null && await PalmImageArchive.exists(path)) {
      await analyze();
      return;
    }
    retryCapture();
  }

  void _setAnalysisError(String stage, PalmAnalysisError err, Object logged) {
    logAnalysisFailure(
      feature: 'PalmAnalysis',
      stage: stage,
      error: logged,
      kind: err.kind.name,
    );
    _lastError = err;
    _error = err.message;
    _phase = PalmPhase.error;
  }
}
