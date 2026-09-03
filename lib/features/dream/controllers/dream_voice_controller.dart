/// Sesli Anlat session — continuous dictation, review, then existing AI.
library;

import 'dart:async';
import 'package:flutter/widgets.dart';

import '../services/dream_voice_input_port.dart';
import '../voice/dream_voice_debug_trace.dart';
import '../voice/dream_voice_failure.dart';
import '../voice/dream_voice_permission.dart';
import '../voice/dream_voice_phase.dart';
import 'dream_voice_capture_session.dart';

class DreamVoiceController extends ChangeNotifier
    with WidgetsBindingObserver {
  DreamVoiceController(this._port) {
    WidgetsBinding.instance.addObserver(this);
  }

  final DreamVoiceInputPort _port;
  final DreamVoiceCaptureSession _session = DreamVoiceCaptureSession();

  DreamVoicePhase _phase = DreamVoicePhase.idle;
  String _transcript = '';
  String? _errorMessage;
  var _disposed = false;

  DreamVoicePhase get phase => _phase;
  String get transcript => _transcript;
  String? get errorMessage => _errorMessage;
  bool get isBusy =>
      _phase == DreamVoicePhase.recording ||
      _phase == DreamVoicePhase.processing;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) return;
    if (!isBusy) return;
    unawaited(_port.cancelListening());
    _phase = DreamVoicePhase.idle;
    _session.reset();
    _transcript = '';
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> start() async {
    if (isBusy) return;
    _errorMessage = null;
    _session.reset();
    _transcript = '';
    DreamVoiceDebugTrace.reset(reason: 'new_narration');
    if (!await _port.isSpeechAvailable()) {
      _fail(DreamVoiceFailure.speechUnavailable());
      return;
    }
    final permission = await _port.requestPermission();
    if (permission != DreamVoicePermission.granted) {
      _fail(DreamVoiceFailure.permissionDeniedFor(permission));
      return;
    }
    _phase = DreamVoicePhase.recording;
    notifyListeners();
    await _beginListening();
  }

  Future<void> stop() async {
    if (_phase != DreamVoicePhase.recording) return;
    _session.stopping = true;
    _phase = DreamVoicePhase.processing;
    notifyListeners();
    await _port.stopListening();
    _completeStop();
  }

  Future<void> listenAgain() async {
    if (isBusy) return;
    await start();
  }

  void editTranscript(String text) {
    if (_phase != DreamVoicePhase.transcribed) return;
    _transcript = text;
    notifyListeners();
  }

  void reset() {
    _port.cancelListening();
    _phase = DreamVoicePhase.idle;
    _session.reset();
    _transcript = '';
    _errorMessage = null;
    DreamVoiceDebugTrace.reset(reason: 'user_cancel');
    notifyListeners();
  }

  Future<void> _beginListening() async {
    _session.listenGeneration += 1;
    final gen = _session.listenGeneration;
    DreamVoiceDebugTrace.listenStart(
      generation: gen,
      phase: _phase.index,
      segments: _session.accumulator.segmentCount,
      totalLen: _session.accumulator.text.length,
    );
    await _port.startListening(
      onResult: (text, isFinal) => _onResult(text, isFinal, gen),
      onError: _onError,
      onListeningEnded: () => _onSessionEnded(gen),
    );
  }

  void _onResult(String text, bool isFinal, int generation) {
    if (_disposed) return;
    if (generation != _session.listenGeneration) {
      DreamVoiceDebugTrace.stale(
        generation: generation,
        activeGeneration: _session.listenGeneration,
        kind: isFinal ? 'final' : 'partial',
      );
      return;
    }
    final capturing = _phase == DreamVoicePhase.recording ||
        (_phase == DreamVoicePhase.processing && _session.stopping);
    if (!capturing) return;
    _session.restartAttempts = 0;
    _session.accumulator.applyResult(text, isFinal, generation: generation);
    _transcript = _session.accumulator.text;
    DreamVoiceDebugTrace.result(
      generation: generation,
      isFinal: isFinal,
      segments: _session.accumulator.segmentCount,
      partialLen: _session.accumulator.partialLength,
      totalLen: _transcript.length,
    );
    notifyListeners();
  }

  void _onSessionEnded(int generation) {
    if (_disposed) return;
    if (generation != _session.listenGeneration) {
      DreamVoiceDebugTrace.stale(
        generation: generation,
        activeGeneration: _session.listenGeneration,
        kind: 'session_end',
      );
      return;
    }
    if (_phase == DreamVoicePhase.processing) {
      if (_session.stopping) _completeStop();
      return;
    }
    if (_phase != DreamVoicePhase.recording) return;
    unawaited(_restartListening('session_end'));
  }

  Future<void> _restartListening(String reason) async {
    if (!_session.canRestart(_phase)) return;
    _session.sealBeforeRecognitionRestart();
    _transcript = _session.accumulator.text;
    DreamVoiceDebugTrace.restart(
      generation: _session.listenGeneration,
      reason: reason,
      segments: _session.accumulator.segmentCount,
      totalLen: _transcript.length,
    );
    _session.restarting = true;
    _session.restartAttempts += 1;
    try {
      await _beginListening();
    } catch (_) {
      // Preserve accumulated narration for manual finish/edit.
    } finally {
      _session.restarting = false;
    }
  }

  void _onError(DreamVoiceFailure failure) {
    if (_disposed || _phase != DreamVoicePhase.recording) return;
    if (failure.isRecoverableDuringCapture) {
      unawaited(_restartListening('recoverable_error'));
      return;
    }
    _fail(failure);
  }

  void _completeStop() {
    if (_phase != DreamVoicePhase.processing) return;
    _session.stopping = false;
    _transcript = _session.sealForReview();
    DreamVoiceDebugTrace.phaseChange(
      phase: DreamVoicePhaseLabel.transcribed,
      segments: _session.accumulator.segmentCount,
      totalLen: _transcript.length,
    );
    _finishFromTranscript();
  }

  void _finishFromTranscript() {
    if (_phase == DreamVoicePhase.transcribed ||
        _phase == DreamVoicePhase.error) {
      return;
    }
    if (_transcript.isEmpty) {
      _fail(DreamVoiceFailure.emptyTranscription());
      return;
    }
    _phase = DreamVoicePhase.transcribed;
    notifyListeners();
  }

  void _fail(DreamVoiceFailure failure) {
    _port.cancelListening();
    _phase = DreamVoicePhase.error;
    _errorMessage = failure.userMessage;
    _session.stopping = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _port.cancelListening();
    super.dispose();
  }
}
