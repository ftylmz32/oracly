/// OR Rehberi STT — one capture; live transcript; optional low-confidence review.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../core/voice/oracly_tts_gate.dart';
import '../services/companion_voice_input_port.dart';
import '../voice/companion_speech_result.dart';
import '../voice/companion_voice_ensure_ready.dart';
import '../voice/companion_voice_failure.dart';
import '../voice/companion_voice_phase.dart';

class CompanionVoiceController extends ChangeNotifier
    with WidgetsBindingObserver {
  CompanionVoiceController(this._port) {
    WidgetsBinding.instance.addObserver(this);
  }
  final CompanionVoiceInputPort _port;
  CompanionVoicePhase _phase = CompanionVoicePhase.idle;
  String _prefix = '';
  String _transcript = '';
  bool _needsReview = false;
  String? _errorMessage;
  bool _closing = false;
  CompanionVoicePhase get phase => _phase;
  String get transcript => _transcript;
  bool get needsReview => _needsReview;
  String? get errorMessage => _errorMessage;
  bool get isListening => _phase == CompanionVoicePhase.listening;
  bool get isRequesting => _phase == CompanionVoicePhase.requesting;
  bool get isActive =>
      isListening || isRequesting;
  String get composerDraft {
    final live = _transcript.trim();
    final prefix = _prefix.trimRight();
    if (prefix.isEmpty) return live;
    return live.isEmpty ? prefix : '$prefix $live';
  }
  Future<void> start({required String existingText}) async {
    if (_phase != CompanionVoicePhase.idle) return;
    await OraclyTtsGate.stop();
    _resetCapture(prefix: existingText);
    _phase = CompanionVoicePhase.requesting;
    notifyListeners();
    final ready = await companionVoiceEnsureReady(_port);
    if (ready != null) {
      _fail(ready);
      return;
    }
    if (_phase != CompanionVoicePhase.requesting) return;
    _phase = CompanionVoicePhase.listening;
    notifyListeners();
    await _port.startListening(
      onResult: _onResult,
      onError: _fail,
      onListeningEnded: _onEnded,
    );
  }
  Future<void> stop() async {
    if (_phase != CompanionVoicePhase.listening || _closing) return;
    await _closeCapture();
  }
  Future<void> cancel() async {
    _closing = true;
    final keep = _prefix;
    try {
      await _port.cancelListening();
    } catch (_) {}
    // Keep typed prefix so settle sync can restore the composer.
    _resetCapture(prefix: keep);
    _phase = CompanionVoicePhase.idle;
    _closing = false;
    notifyListeners();
  }
  void consumeTranscript() {
    if (_transcript.isEmpty && !_needsReview) return;
    _resetCapture();
    notifyListeners();
  }
  Future<void> retry({required String existingText}) async {
    if (isActive) return;
    _errorMessage = null;
    _needsReview = false;
    await start(existingText: existingText);
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_port.cancelListening());
    super.dispose();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed || !isActive) return;
    unawaited(cancel());
  }
  void _onResult(CompanionSpeechResult result) {
    if (_phase != CompanionVoicePhase.listening && !_closing) return;
    final next = result.text.trim();
    final changed = next != _transcript;
    if (changed) _transcript = next;
    if (_phase == CompanionVoicePhase.listening && changed) {
      notifyListeners();
    }
    if (!result.isFinal) return;
    if (result.isLowConfidence) _needsReview = true;
    if (_closing) return;
    unawaited(_closeCapture());
  }
  void _onEnded() {
    if (_closing || _phase != CompanionVoicePhase.listening) return;
    unawaited(_closeCapture());
  }
  Future<void> _closeCapture() async {
    if (_closing) return;
    _closing = true;
    try {
      await _port.stopListening();
      if (_phase == CompanionVoicePhase.idle) return;
      if (_transcript.isEmpty) {
        _fail(CompanionVoiceFailure.emptyTranscription());
        return;
      }
      _phase = CompanionVoicePhase.idle;
      notifyListeners();
    } finally {
      _closing = false;
    }
  }
  void _fail(CompanionVoiceFailure failure) {
    unawaited(_port.cancelListening());
    _resetCapture();
    _phase = CompanionVoicePhase.idle;
    _errorMessage = failure.userMessage;
    notifyListeners();
  }
  void _resetCapture({String prefix = ''}) {
    _transcript = '';
    _needsReview = false;
    _errorMessage = null;
    _prefix = prefix;
  }
}
