/// OS speech-to-text for dreams — TR/EN/RU locale, no audio persistence.
library;

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/l10n/l10n.dart';
import '../voice/dream_speech_locale.dart';
import '../voice/dream_voice_failure.dart';
import '../voice/dream_voice_permission.dart';
import 'dream_voice_input_port.dart';

class SpeechDreamVoiceInput extends DreamVoiceInputPort {
  SpeechDreamVoiceInput({
    SpeechToText? speech,
    String Function()? languageCode,
  })  : _speech = speech ?? SpeechToText(),
        _languageCode = languageCode ?? (() => OraclyL10n.code);

  final SpeechToText _speech;
  final String Function() _languageCode;
  String? _localeId;
  bool _initialized = false;
  void Function(DreamVoiceFailure)? _onError;
  VoidCallback? _onEnded;

  @override
  bool get isAvailable => true;

  @override
  Future<bool> isSpeechAvailable() async {
    try {
      if (!await _ensureInitialized()) return false;
      return await _resolveLocale() != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<DreamVoicePermission> requestPermission() async {
    try {
      final mic = await Permission.microphone.request();
      if (mic.isPermanentlyDenied) {
        return DreamVoicePermission.permanentlyDenied;
      }
      if (!mic.isGranted) return DreamVoicePermission.denied;
      if (!await _ensureInitialized()) {
        return DreamVoicePermission.unavailable;
      }
      if (await _resolveLocale() == null) {
        return DreamVoicePermission.unavailable;
      }
      return DreamVoicePermission.granted;
    } catch (_) {
      return DreamVoicePermission.unavailable;
    }
  }

  @override
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    required void Function(DreamVoiceFailure failure) onError,
    VoidCallback? onListeningEnded,
  }) async {
    _onError = onError;
    _onEnded = onListeningEnded;
    final localeId = await _resolveLocale();
    if (localeId == null) {
      onError(DreamVoiceFailure.speechUnavailable());
      return;
    }
    try {
      await _speech.listen(
        onResult: (result) =>
            onResult(result.recognizedWords, result.finalResult),
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          cancelOnError: false,
          partialResults: true,
          localeId: localeId,
          listenFor: const Duration(minutes: 5),
          pauseFor: const Duration(seconds: 12),
        ),
      );
    } catch (_) {
      onError(DreamVoiceFailure.speechError());
    }
  }

  @override
  Future<void> stopListening() async {
    if (_speech.isListening) await _speech.stop();
  }

  @override
  Future<void> cancelListening() async {
    if (_speech.isListening) await _speech.cancel();
  }

  Future<bool> _ensureInitialized() async {
    if (_initialized && _speech.isAvailable) return true;
    _initialized = await _speech.initialize(
      debugLogging: false,
      onError: (error) => _routeSpeechError(error.errorMsg),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') _onEnded?.call();
      },
    );
    return _initialized && _speech.isAvailable;
  }

  Future<String?> _resolveLocale() async {
    if (_localeId != null) return _localeId;
    final locales = await _speech.locales();
    _localeId = resolveDreamSpeechLocale(
      locales.map((locale) => locale.localeId),
      _languageCode(),
    );
    return _localeId;
  }

  void _routeSpeechError(String raw) {
    final failure = _mapSpeechError(raw);
    if (_isRecoverable(raw)) {
      _onEnded?.call();
      return;
    }
    _onError?.call(failure);
  }

  bool _isRecoverable(String raw) {
    final id = raw.toLowerCase();
    return id.contains('no_match') ||
        id.contains('no-match') ||
        id.contains('timeout') ||
        id.contains('speech_timeout');
  }

  DreamVoiceFailure _mapSpeechError(String raw) {
    final id = raw.toLowerCase();
    if (id.contains('permission')) return DreamVoiceFailure.permissionDenied();
    if (id.contains('network')) return DreamVoiceFailure.network();
    if (id.contains('audio')) {
      return DreamVoiceFailure.microphoneUnavailable();
    }
    if (id.contains('timeout')) return DreamVoiceFailure.timeout();
    if (id.contains('no_match') || id.contains('no-match')) {
      return DreamVoiceFailure.emptyTranscription();
    }
    return DreamVoiceFailure.speechError();
  }
}
