/// Persisted OR chat output mode - text / voice replies / conversation.
library;

import 'package:flutter/foundation.dart';

import '../../../core/personality/or_response_depth.dart';
import '../../../core/voice/or_speech_grant.dart';
import '../../../core/voice/oracly_proxy_speech.dart';
import '../../../core/voice/oracly_tts_gate.dart';
import '../models/or_chat_output_mode.dart';

part 'companion_output_speech.dart';

class CompanionOutputController extends ChangeNotifier {
  CompanionOutputController({
    required this._persistMode,
    OrChatOutputMode Function()? readMode,
    OrResponseDepth Function()? readDepth,
  })  : _readMode = readMode ?? (() => OrChatOutputMode.text),
        _readDepth = readDepth ?? (() => OrResponseDepth.fallback) {
    _session = this;
    OraclyTtsGate.speaking.addListener(_onSpeaking);
    OraclyTtsGate.paused.addListener(_onSpeaking);
    OraclyTtsGate.unavailable.addListener(_onSpeaking);
  }

  final Future<void> Function(OrChatOutputMode mode) _persistMode;
  final OrChatOutputMode Function() _readMode;
  final OrResponseDepth Function() _readDepth;
  static CompanionOutputController? _session;
  String? _lastSpoken;
  String? _lastGrant;
  int _speakGen = 0;
  bool? _lastSpeaking;
  bool? _lastPaused;
  bool? _lastUnavailable;

  OrChatOutputMode get mode => _readMode();
  bool get isVoice => mode.isVoice;
  bool get isConversation => mode.isConversation;
  bool get isSpeaking => OraclyTtsGate.speaking.value;
  bool get isPaused => OraclyTtsGate.paused.value;
  bool get voiceUnavailable => OraclyTtsGate.unavailable.value;
  bool get canReplay =>
      isVoice && !isSpeaking && (_lastSpoken?.trim().isNotEmpty ?? false);

  void syncFromSettings() => notifyListeners();

  void noteSpeech() => notifyListeners();

  static void dropSessionSpeech() {
    _session?.dropSpoken();
    OraclyProxySpeech.releaseCaches();
  }

  Future<void> setMode(OrChatOutputMode mode) async {
    if (!mode.isVoice) await interrupt();
    if (_readMode() != mode) await _persistMode(mode);
    if (mode.isVoice) {
      final tts = OraclyTtsGate.engine;
      OraclyTtsGate.unavailable.value =
          tts == null || !await tts.isAvailable();
    }
    notifyListeners();
  }

  Future<void> onUserSend() => interrupt();

  Future<void> pause() async {
    await OraclyTtsGate.pause();
    notifyListeners();
  }

  Future<void> resume() async {
    await OraclyTtsGate.resume();
    notifyListeners();
  }

  Future<void> togglePause() async {
    if (isPaused) {
      await resume();
    } else if (isSpeaking) {
      await pause();
    }
  }

  String _spoken(String? text) =>
      _readDepth().cap(text ?? '', spoken: true);

  Future<void> stop() async {
    await OraclyTtsGate.stop();
    notifyListeners();
  }

  Future<void> interrupt() async {
    _speakGen++;
    await OraclyTtsGate.interrupt();
    notifyListeners();
  }

  void _onSpeaking() {
    final speaking = OraclyTtsGate.speaking.value;
    final paused = OraclyTtsGate.paused.value;
    final unavailable = OraclyTtsGate.unavailable.value;
    if (speaking == _lastSpeaking &&
        paused == _lastPaused &&
        unavailable == _lastUnavailable) {
      return;
    }
    _lastSpeaking = speaking;
    _lastPaused = paused;
    _lastUnavailable = unavailable;
    notifyListeners();
  }

  @override
  void dispose() {
    if (identical(_session, this)) _session = null;
    OraclyTtsGate.speaking.removeListener(_onSpeaking);
    OraclyTtsGate.paused.removeListener(_onSpeaking);
    OraclyTtsGate.unavailable.removeListener(_onSpeaking);
    super.dispose();
  }
}
