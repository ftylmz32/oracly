/// OR-1180 — Streaming interpretation events.
library;

import 'interpretation_result.dart';

enum InterpretationStreamPhase {
  started,
  sectionPartial,
  sectionComplete,
  completed,
  failed,
}

class InterpretationStreamEvent {
  const InterpretationStreamEvent({
    required this.phase,
    this.sectionKey,
    this.partialText,
    this.result,
    this.error,
    this.progress = 0,
  });

  final InterpretationStreamPhase phase;
  final InterpretationSectionKey? sectionKey;
  final String? partialText;
  final InterpretationResult? result;
  final Object? error;
  final double progress;
}
