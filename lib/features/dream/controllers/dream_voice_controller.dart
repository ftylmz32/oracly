/// Sesli Anlat session — recording → transcript review, then existing AI.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../services/dream_voice_input_port.dart';
import '../voice/dream_voice_failure.dart';
import '../voice/dream_voice_permission.dart';
import '../voice/dream_voice_phase.dart';

class DreamVoiceController extends ChangeNotifier
    with WidgetsBindingObserver {
  DreamVoiceController(this._port) {
    WidgetsBinding.instance.addObserver(this);
  }

  final DreamVoiceInputPort _port;

  DreamVoicePhase _phase = DreamVoicePhase.idle;
  String _transcript = '';
  String? _errorMessage;

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

    // Prevent ghost audio by stopping STT immediately on background/screen lock.
    unawaited(_port.cancelListening());
    _phase = DreamVoicePhase.idle;
    _transcript = '';
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> start() async {
    if (isBusy) return;
    _errorMessage = null;
    _transcript = '';
    if (!await _port.isSpeechAvailable()) {
      _fail(DreamVoiceFailure.speechUnavailable());
      return;
    }
    final permission = await _port.requestPermission();
    if (permission != DreamVoicePermission.granted) {
      _fail(_permissionFailure(permission));
      return;
    }
    _phase = DreamVoicePhase.recording;
    notifyListeners();
    await _port.startListening(
      onResult: _onResult,
      onError: _fail,
      onListeningEnded: _onEnded,
    );
  }

  Future<void> stop() async {
    if (_phase != DreamVoicePhase.recording) return;
    _phase = DreamVoicePhase.processing;
    notifyListeners();
    await _port.stopListening();
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
    _transcript = '';
    _errorMessage = null;
    notifyListeners();
  }

  void _onResult(String text, bool isFinal) {
    _transcript = text.trim();
    if (_phase == DreamVoicePhase.recording) notifyListeners();
    if (isFinal) _finishFromTranscript();
  }

  void _onEnded() {
    if (_phase == DreamVoicePhase.recording ||
        _phase == DreamVoicePhase.processing) {
      _finishFromTranscript();
    }
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
    notifyListeners();
  }

  DreamVoiceFailure _permissionFailure(DreamVoicePermission permission) {
    return switch (permission) {
      DreamVoicePermission.denied => DreamVoiceFailure.permissionDenied(),
      DreamVoicePermission.permanentlyDenied =>
        DreamVoiceFailure.permissionPermanentlyDenied(),
      DreamVoicePermission.unavailable =>
        DreamVoiceFailure.microphoneUnavailable(),
      DreamVoicePermission.granted => DreamVoiceFailure.speechUnavailable(),
    };
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _port.cancelListening();
    super.dispose();
  }
}
