/// OS speech-to-text for OR Rehberi — Turkish locale, no audio upload.
library;

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../voice/companion_speech_result.dart';
import '../voice/companion_voice_failure.dart';
import '../voice/companion_voice_permission.dart';
import 'companion_voice_input_port.dart';

class SpeechCompanionVoiceInput extends CompanionVoiceInputPort {
  SpeechCompanionVoiceInput({SpeechToText? speech})
      : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;
  String? _turkishLocaleId;
  bool _initialized = false;
  void Function(CompanionVoiceFailure)? _onError;
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
  Future<CompanionVoicePermission> requestPermission() async {
    try {
      final mic = await Permission.microphone.request();
      if (mic.isPermanentlyDenied) {
        return CompanionVoicePermission.permanentlyDenied;
      }
      if (!mic.isGranted) return CompanionVoicePermission.denied;
      if (!await _ensureInitialized()) {
        return CompanionVoicePermission.unavailable;
      }
      if (await _resolveTurkishLocale() == null) {
        return CompanionVoicePermission.unavailable;
      }
      return CompanionVoicePermission.granted;
    } catch (_) {
      return CompanionVoicePermission.unavailable;
    }
  }

  @override
  Future<void> startListening({
    required void Function(CompanionSpeechResult result) onResult,
    required void Function(CompanionVoiceFailure failure) onError,
    VoidCallback? onListeningEnded,
  }) async {
    _onError = onError;
    _onEnded = onListeningEnded;
    final localeId = await _resolveTurkishLocale();
    if (localeId == null) {
      onError(CompanionVoiceFailure.speechUnavailable());
      return;
    }
    try {
      await _speech.listen(
        onResult: (result) {
          final rated = result.hasConfidenceRating && result.confidence > 0;
          onResult(
            CompanionSpeechResult(
              text: result.recognizedWords,
              isFinal: result.finalResult,
              confidence: rated ? result.confidence : null,
            ),
          );
        },
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
      onError(CompanionVoiceFailure.speechError());
    }
  }

  @override
  Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (_) {}
  }

  @override
  Future<void> cancelListening() async {
    try {
      await _speech.cancel();
    } catch (_) {}
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

  CompanionVoiceFailure _mapSpeechError(String raw) {
    final id = raw.toLowerCase();
    if (id.contains('permission')) {
      return CompanionVoiceFailure.permissionDenied();
    }
    if (id.contains('network')) return CompanionVoiceFailure.network();
    if (id.contains('audio')) {
      return CompanionVoiceFailure.microphoneUnavailable();
    }
    if (id.contains('timeout')) return CompanionVoiceFailure.timeout();
    if (id.contains('no_match') || id.contains('no-match')) {
      return CompanionVoiceFailure.emptyTranscription();
    }
    return CompanionVoiceFailure.speechError();
  }
}
