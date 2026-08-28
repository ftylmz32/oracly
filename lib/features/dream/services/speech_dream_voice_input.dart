/// OS speech-to-text for dreams — Turkish locale, no audio persistence.
library;

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../voice/dream_voice_failure.dart';
import '../voice/dream_voice_permission.dart';
import 'dream_voice_input_port.dart';

class SpeechDreamVoiceInput extends DreamVoiceInputPort {
  SpeechDreamVoiceInput({SpeechToText? speech})
      : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;
  String? _turkishLocaleId;
  bool _initialized = false;
  void Function(DreamVoiceFailure)? _onError;
  VoidCallback? _onEnded;

  @override
  bool get isAvailable => true;

  @override
  Future<bool> isSpeechAvailable() async {
    try {
      if (!await _ensureInitialized()) return false;
      return await _resolveTurkishLocale() != null;
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
      if (await _resolveTurkishLocale() == null) {
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
    final localeId = await _resolveTurkishLocale();
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
          cancelOnError: true,
          partialResults: true,
          localeId: localeId,
          listenFor: const Duration(minutes: 3),
          pauseFor: const Duration(seconds: 8),
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
      onError: (error) => _onError?.call(_mapSpeechError(error.errorMsg)),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') _onEnded?.call();
      },
    );
    return _initialized && _speech.isAvailable;
  }

  Future<String?> _resolveTurkishLocale() async {
    if (_turkishLocaleId != null) return _turkishLocaleId;
    final locales = await _speech.locales();
    for (final locale in locales) {
      final id = locale.localeId.toLowerCase().replaceAll('-', '_');
      if (id == 'tr' || id == 'tr_tr' || id.startsWith('tr_')) {
        _turkishLocaleId = locale.localeId;
        return _turkishLocaleId;
      }
    }
    return null;
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
