/// SPRINT-003 — Companion session state.
library;

import '../../ai/production/ai_failure.dart';
import 'conversation.dart';
import 'reflection_context.dart';

enum CompanionPhase {
  initializing,
  welcome,
  conversing,
  thinking,
  error,
}

/// Reachability is a status — never replaces the chat shell.
enum CompanionLinkStatus {
  online,
  connecting,
  reconnecting,
  offline,
}

class CompanionState {
  const CompanionState({
    this.phase = CompanionPhase.welcome,
    this.conversation,
    this.context,
    this.errorMessage,
    this.lastFailedText,
    this.lastFailureKind,
    this.streamingBuffer = '',
    this.isStreaming = false,
    this.linkStatus = CompanionLinkStatus.online,
  });

  final CompanionPhase phase;
  final Conversation? conversation;
  final ReflectionContext? context;
  final String? errorMessage;
  final String? lastFailedText;
  final AiFailureKind? lastFailureKind;
  final String streamingBuffer;
  final bool isStreaming;
  final CompanionLinkStatus linkStatus;

  bool get isBusy =>
      phase == CompanionPhase.thinking || isStreaming;

  CompanionState copyWith({
    CompanionPhase? phase,
    Conversation? conversation,
    ReflectionContext? context,
    String? errorMessage,
    String? lastFailedText,
    AiFailureKind? lastFailureKind,
    bool clearFailureKind = false,
    String? streamingBuffer,
    bool? isStreaming,
    CompanionLinkStatus? linkStatus,
  }) {
    return CompanionState(
      phase: phase ?? this.phase,
      conversation: conversation ?? this.conversation,
      context: context ?? this.context,
      errorMessage: errorMessage,
      lastFailedText: lastFailedText,
      lastFailureKind: clearFailureKind
          ? null
          : (lastFailureKind ?? this.lastFailureKind),
      streamingBuffer: streamingBuffer ?? this.streamingBuffer,
      isStreaming: isStreaming ?? this.isStreaming,
      linkStatus: linkStatus ?? this.linkStatus,
    );
  }
}
