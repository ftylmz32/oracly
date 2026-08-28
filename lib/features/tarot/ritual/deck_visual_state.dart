/// Presentation deck visuals ? never duplicates domain draw/shuffle truth.
library;

import "dart:ui" show Offset;

import "package:flutter/foundation.dart";

import "tarot_ritual_stage.dart";

@immutable
class DeckVisualState {
  const DeckVisualState({
    this.stage = TarotRitualStage.deckReady,
    this.stackDepth = 1.0,
    this.baseOffset = Offset.zero,
    this.perspective = 0.0012,
    this.shuffleProgress = 0,
    this.cutProgress = 0,
    this.dragProgress = 0,
    this.extractionProgress = 0,
    this.flipProgress = 0,
    this.shuffleMotions = 0,
    this.cutSeparated = false,
  });

  final TarotRitualStage stage;
  final double stackDepth;
  final Offset baseOffset;
  final double perspective;
  final double shuffleProgress;
  final double cutProgress;
  final double dragProgress;
  final double extractionProgress;
  final double flipProgress;
  final int shuffleMotions;
  final bool cutSeparated;

  DeckVisualState copyWith({
    TarotRitualStage? stage,
    double? stackDepth,
    Offset? baseOffset,
    double? perspective,
    double? shuffleProgress,
    double? cutProgress,
    double? dragProgress,
    double? extractionProgress,
    double? flipProgress,
    int? shuffleMotions,
    bool? cutSeparated,
  }) {
    return DeckVisualState(
      stage: stage ?? this.stage,
      stackDepth: stackDepth ?? this.stackDepth,
      baseOffset: baseOffset ?? this.baseOffset,
      perspective: perspective ?? this.perspective,
      shuffleProgress: shuffleProgress ?? this.shuffleProgress,
      cutProgress: cutProgress ?? this.cutProgress,
      dragProgress: dragProgress ?? this.dragProgress,
      extractionProgress: extractionProgress ?? this.extractionProgress,
      flipProgress: flipProgress ?? this.flipProgress,
      shuffleMotions: shuffleMotions ?? this.shuffleMotions,
      cutSeparated: cutSeparated ?? this.cutSeparated,
    );
  }
}
