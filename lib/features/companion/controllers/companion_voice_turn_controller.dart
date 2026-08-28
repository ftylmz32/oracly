/// Voice conversation turns — tap → listen → think → speak → ready.
/// Interrupts never leave mic or playback stuck; never auto-reopen mic.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import '../voice/or_voice_turn_phase.dart';
import 'companion_controller.dart';
import 'companion_output_controller.dart';
import 'companion_voice_controller.dart';
import 'companion_voice_turn_commit.dart';

typedef CompanionTurnSender = Future<void> Function(String text);

class CompanionVoiceTurnController extends ChangeNotifier
    with WidgetsBindingObserver {
  CompanionVoiceTurnController({
    required this._voice,
    required this._output,
    this._session,
  }) {
    _voice.addListener(_onVoice);
    _session?.addListener(_onSession);
    WidgetsBinding.instance.addObserver(this);
  }
  final CompanionVoiceController _voice;
  final CompanionOutputController _output;
  final CompanionController? _session;
  CompanionTurnSender? _send;

  OrVoiceTurnPhase _phase = OrVoiceTurnPhase.ready;
  int _turn = 0;
  bool _active = false;

  OrVoiceTurnPhase get phase => _phase;
  bool get isActive => _active;
  bool get isReady => _active && _phase == OrVoiceTurnPhase.ready;

  void bindSender(CompanionTurnSender send) => _send = send;

  void setActive(bool value) {
    if (_active == value) return;
    _active = value;
    if (!value) {
      unawaited(_reset(ready: false));
      return;
    }
    _phase = OrVoiceTurnPhase.ready;
    notifyListeners();
  }
  Future<void> onMicTap() async {
    if (!_active) return;
    if (_phase == OrVoiceTurnPhase.listening) {
      await _voice.stop();
      return;
    }
    if (_phase == OrVoiceTurnPhase.speaking ||
        _phase == OrVoiceTurnPhase.thinking ||
        _phase == OrVoiceTurnPhase.settling) {
      await _bargeIn();
      return;
    }
    if (_phase != OrVoiceTurnPhase.ready || _voice.isActive) return;
    await _output.interrupt();
    _phase = OrVoiceTurnPhase.listening;
    notifyListeners();
    await _voice.start(existingText: '');
    if (!_voice.isListening && _phase == OrVoiceTurnPhase.listening) {
      _phase = OrVoiceTurnPhase.ready;
      notifyListeners();
    }
  }
  Future<void> cancel() => _reset(ready: _active);

  Future<void> handleExternalInterrupt() => _reset(ready: _active);

  Future<void> _bargeIn() async {
    _turn++;
    await _output.interrupt();
    await _voice.cancel();
    _phase = OrVoiceTurnPhase.ready;
    notifyListeners();
    await onMicTap();
  }
  Future<void> _reset({required bool ready}) async {
    _turn++;
    await _voice.cancel();
    await _output.interrupt();
    _phase = OrVoiceTurnPhase.ready;
    if (!ready) _active = false;
    notifyListeners();
  }
  void _onVoice() {
    if (!_active || _phase != OrVoiceTurnPhase.listening) return;
    if (_voice.isActive) return;
    if (_voice.errorMessage != null || _voice.transcript.trim().isEmpty) {
      _phase = OrVoiceTurnPhase.ready;
      notifyListeners();
      return;
    }
    if (_voice.needsReview) {
      _phase = OrVoiceTurnPhase.ready;
      notifyListeners();
      return;
    }
    unawaited(_runCommit(_voice.transcript.trim()));
  }
  Future<void> _runCommit(String text) async {
    final id = ++_turn;
    final next = await commitVoiceTurn(
      text: text,
      turnId: id,
      currentTurn: () => _turn,
      isActive: () => _active,
      output: _output,
      send: _send,
      setPhase: (phase) {
        _phase = phase;
        notifyListeners();
      },
    );
    if (id != _turn) return;
    _voice.consumeTranscript();
    _phase = next;
    notifyListeners();
  }
  void _onSession() {
    if (!_active) return;
    if (_phase == OrVoiceTurnPhase.thinking &&
        _session?.state.errorMessage != null) {
      _phase = OrVoiceTurnPhase.ready;
      notifyListeners();
    }
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) return;
    if (!_active && !_voice.isActive && !_output.isSpeaking) return;
    unawaited(handleExternalInterrupt());
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _voice.removeListener(_onVoice);
    _session?.removeListener(_onSession);
    _turn++;
    super.dispose();
  }
}
