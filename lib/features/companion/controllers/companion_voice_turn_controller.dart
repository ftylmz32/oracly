/// Voice conversation turns — tap → listen → think → speak → ready.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import '../voice/or_voice_turn_phase.dart';
import 'companion_controller.dart';
import 'companion_output_controller.dart';
import 'companion_voice_controller.dart';
import 'companion_voice_turn_handlers.dart';
import 'companion_voice_turn_safe.dart';

typedef CompanionTurnSender = Future<void> Function(String text);

class CompanionVoiceTurnController extends ChangeNotifier
    with WidgetsBindingObserver, CompanionVoiceTurnSafe {
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
  void bindSender(CompanionTurnSender send) {
    if (isDisposed) return;
    _send = send;
  }
  void setActive(bool value) {
    if (isDisposed || _active == value) return;
    _active = value;
    if (!value) {
      unawaited(_reset(ready: false));
      return;
    }
    _phase = OrVoiceTurnPhase.ready;
    safeNotify();
  }
  Future<void> onMicTap() async {
    if (isDisposed || !_active) return;
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
    if (isDisposed) return;
    _phase = OrVoiceTurnPhase.listening;
    safeNotify();
    await _voice.start(existingText: '');
    if (isDisposed) return;
    if (!_voice.isListening && _phase == OrVoiceTurnPhase.listening) {
      _phase = OrVoiceTurnPhase.ready;
      safeNotify();
    }
  }
  Future<void> cancel() => _reset(ready: _active);
  Future<void> handleExternalInterrupt() => _reset(ready: _active);
  Future<void> _bargeIn() async {
    if (isDisposed) return;
    _turn++;
    await _output.interrupt();
    await _voice.cancel();
    if (isDisposed) return;
    _phase = OrVoiceTurnPhase.ready;
    safeNotify();
    await onMicTap();
  }
  Future<void> _reset({required bool ready}) async {
    if (isDisposed) return;
    _turn++;
    await _voice.cancel();
    await _output.interrupt();
    if (isDisposed) return;
    _phase = OrVoiceTurnPhase.ready;
    if (!ready) _active = false;
    safeNotify();
  }
  void _onVoice() => companionVoiceOnEnded(
        disposed: isDisposed,
        active: _active,
        phase: _phase,
        voice: _voice,
        setPhase: (p) => _phase = p,
        notify: safeNotify,
        commit: (text) => unawaited(_runCommit(text)),
      );
  Future<void> _runCommit(String text) => companionVoiceRunCommit(
        text: text,
        turnId: ++_turn,
        currentTurn: () => _turn,
        alive: () => !isDisposed && _active,
        voice: _voice,
        output: _output,
        send: _send,
        setPhase: (p) => _phase = p,
        notify: safeNotify,
        applyPhase: (p) => _phase = p,
      );
  void _onSession() => companionVoiceOnSessionError(
        disposed: isDisposed,
        active: _active,
        phase: _phase,
        session: _session,
        setPhase: (p) => _phase = p,
        notify: safeNotify,
      );
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (isDisposed || state == AppLifecycleState.resumed) return;
    if (!_active && !_voice.isActive && !_output.isSpeaking) return;
    unawaited(handleExternalInterrupt());
  }
  @override
  void dispose() {
    if (isDisposed) return;
    markDisposed();
    _active = false;
    WidgetsBinding.instance.removeObserver(this);
    _voice.removeListener(_onVoice);
    _session?.removeListener(_onSession);
    _send = null;
    _turn++;
    super.dispose();
  }
}
