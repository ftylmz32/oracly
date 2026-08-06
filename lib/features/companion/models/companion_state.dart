/// SPRINT-003 — Companion session state.
library;

import 'conversation.dart';
import 'reflection_context.dart';

enum CompanionPhase {
  welcome,
  conversing,
  thinking,
  error,
}

class CompanionState {
  const CompanionState({
    this.phase = CompanionPhase.welcome,
    this.conversation,
    this.context,
    this.errorMessage,
    this.streamingBuffer = '',
    this.isStreaming = false,
  });

  final CompanionPhase phase;
  final Conversation? conversation;
  final ReflectionContext? context;
  final String? errorMessage;
  final String streamingBuffer;
  final bool isStreaming;

  bool get isBusy =>
      phase == CompanionPhase.thinking || isStreaming;

  CompanionState copyWith({
    CompanionPhase? phase,
    Conversation? conversation,
    ReflectionContext? context,
    String? errorMessage,
    String? streamingBuffer,
    bool? isStreaming,
  }) {
    return CompanionState(
      phase: phase ?? this.phase,
      conversation: conversation ?? this.conversation,
      context: context ?? this.context,
      errorMessage: errorMessage,
      streamingBuffer: streamingBuffer ?? this.streamingBuffer,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}
