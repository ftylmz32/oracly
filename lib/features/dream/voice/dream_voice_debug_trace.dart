/// Debug-only Dream voice tracing — lengths/counts, never spoken content.
library;

import 'package:flutter/foundation.dart';

enum DreamVoicePhaseLabel { idle, recording, processing, transcribed, error }

abstract final class DreamVoiceDebugTrace {
  DreamVoiceDebugTrace._();

  static void listenStart({
    required int generation,
    required int phase,
    required int segments,
    required int totalLen,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      '[DreamVoice] listenStart gen=$generation phase=$phase '
      'segments=$segments totalLen=$totalLen',
    );
  }

  static void result({
    required int generation,
    required bool isFinal,
    required int segments,
    required int partialLen,
    required int totalLen,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      '[DreamVoice] result gen=$generation kind=${isFinal ? 'final' : 'partial'} '
      'segments=$segments partialLen=$partialLen totalLen=$totalLen',
    );
  }

  static void restart({
    required int generation,
    required String reason,
    required int segments,
    required int totalLen,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      '[DreamVoice] restart after gen=$generation reason=$reason '
      'segments=$segments totalLen=$totalLen',
    );
  }

  static void stale({
    required int generation,
    required int activeGeneration,
    required String kind,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      '[DreamVoice] stale $kind gen=$generation active=$activeGeneration',
    );
  }

  static void phaseChange({
    required DreamVoicePhaseLabel phase,
    required int segments,
    required int totalLen,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      '[DreamVoice] phase=${phase.name} segments=$segments totalLen=$totalLen',
    );
  }

  static void reset({required String reason}) {
    if (!kDebugMode) return;
    debugPrint('[DreamVoice] reset reason=$reason');
  }
}
