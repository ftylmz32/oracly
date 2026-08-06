/// OR-1110 — Riverpod providers for AI core.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/mock_ai_repository.dart';
import '../data/repositories/mock_astrology_ai_repository.dart';
import '../data/repositories/mock_dream_ai_repository.dart';
import '../data/repositories/mock_energy_ai_repository.dart';
import '../data/repositories/mock_tarot_ai_repository.dart';
import '../domain/models/ai_conversation.dart';
import '../domain/models/ai_message.dart';
import '../domain/models/token_usage.dart';
import '../domain/repositories/ai_repository.dart';
import '../domain/repositories/astrology_ai_repository.dart';
import '../domain/repositories/dream_ai_repository.dart';
import '../domain/repositories/energy_ai_repository.dart';
import '../domain/repositories/tarot_ai_repository.dart';
import '../services/conversation_memory.dart';
import '../services/openai_service.dart';

// ── Infrastructure ─────────────────────────────────────────────────

final openAIServiceProvider = Provider<OpenAIService>((ref) {
  return MockOpenAIService();
});

final conversationMemoryProvider = Provider<ConversationMemory>((ref) {
  return ConversationMemory();
});

// ── Repositories ───────────────────────────────────────────────────

final aiRepositoryProvider = Provider<AIRepository>((ref) {
  return MockAIRepository(
    memory: ref.watch(conversationMemoryProvider),
    openAI: ref.watch(openAIServiceProvider),
  );
});

final tarotAIRepositoryProvider = Provider<TarotAIRepository>((ref) {
  return MockTarotAIRepository(openAI: ref.watch(openAIServiceProvider));
});

final dreamAIRepositoryProvider = Provider<DreamAIRepository>((ref) {
  return MockDreamAIRepository(openAI: ref.watch(openAIServiceProvider));
});

final astrologyAIRepositoryProvider = Provider<AstrologyAIRepository>((ref) {
  return MockAstrologyAIRepository(openAI: ref.watch(openAIServiceProvider));
});

final energyAIRepositoryProvider = Provider<EnergyAIRepository>((ref) {
  return MockEnergyAIRepository(openAI: ref.watch(openAIServiceProvider));
});

// ── AIProvider — root AI state ─────────────────────────────────────

final aiProvider = AsyncNotifierProvider<AINotifier, AIState>(AINotifier.new);

class AIState {
  const AIState({
    this.activeConversationId,
    this.isThinking = false,
    this.error,
  });

  final String? activeConversationId;
  final bool isThinking;
  final String? error;

  AIState copyWith({
    String? activeConversationId,
    bool? isThinking,
    String? error,
  }) {
    return AIState(
      activeConversationId: activeConversationId ?? this.activeConversationId,
      isThinking: isThinking ?? this.isThinking,
      error: error,
    );
  }
}

class AINotifier extends AsyncNotifier<AIState> {
  @override
  Future<AIState> build() async => const AIState();

  Future<void> startConversation({
    required String title,
    AIConversationKind kind = AIConversationKind.general,
  }) async {
    final repo = ref.read(aiRepositoryProvider);
    final conv = await repo.createConversation(title: title, kind: kind);
    state = AsyncData(AIState(activeConversationId: conv.id));
  }

  void setThinking(bool value) {
    final current = state.value ?? const AIState();
    state = AsyncData(current.copyWith(isThinking: value));
  }
}

// ── ConversationProvider ───────────────────────────────────────────

final conversationProvider =
    AsyncNotifierProvider<ConversationNotifier, AIConversation?>(
  ConversationNotifier.new,
);

class ConversationNotifier extends AsyncNotifier<AIConversation?> {
  @override
  Future<AIConversation?> build() async => null;

  Future<void> load(String id) async {
    state = const AsyncLoading();
    state = AsyncData(await ref.read(aiRepositoryProvider).getConversation(id));
  }

  Future<void> send(String message) async {
    final conv = state.value;
    if (conv == null) return;

    ref.read(aiProvider.notifier).setThinking(true);
    try {
      await ref.read(aiRepositoryProvider).sendMessage(
            conversationId: conv.id,
            userMessage: message,
          );
      ref.read(tokenUsageProvider.notifier).record(message.length ~/ 4 + 120);
      await load(conv.id);
    } finally {
      ref.read(aiProvider.notifier).setThinking(false);
    }
  }

  Future<void> regenerate(String messageId) async {
    final conv = state.value;
    if (conv == null) return;
    await ref.read(aiRepositoryProvider).regenerateMessage(
          conversationId: conv.id,
          messageId: messageId,
        );
    await load(conv.id);
  }

  Future<void> retry(String messageId) async {
    final conv = state.value;
    if (conv == null) return;
    await ref.read(aiRepositoryProvider).retryMessage(
          conversationId: conv.id,
          messageId: messageId,
        );
    await load(conv.id);
  }
}

// ── StreamingProvider ────────────────────────────────────────────

final streamingProvider =
    NotifierProvider<StreamingNotifier, StreamingState>(StreamingNotifier.new);

class StreamingState {
  const StreamingState({
    this.isStreaming = false,
    this.buffer = '',
    this.messageId,
  });

  final bool isStreaming;
  final String buffer;
  final String? messageId;

  StreamingState copyWith({
    bool? isStreaming,
    String? buffer,
    String? messageId,
  }) {
    return StreamingState(
      isStreaming: isStreaming ?? this.isStreaming,
      buffer: buffer ?? this.buffer,
      messageId: messageId ?? this.messageId,
    );
  }
}

class StreamingNotifier extends Notifier<StreamingState> {
  @override
  StreamingState build() => const StreamingState();

  Future<void> stream({
    required String conversationId,
    required String userMessage,
  }) async {
    final messageId = 'stream_${DateTime.now().millisecondsSinceEpoch}';
    state = StreamingState(isStreaming: true, messageId: messageId);

    final stream = ref.read(aiRepositoryProvider).streamMessage(
          conversationId: conversationId,
          userMessage: userMessage,
        );

    await for (final chunk in stream) {
      state = state.copyWith(buffer: state.buffer + chunk);
    }

    state = state.copyWith(isStreaming: false);
    ref.read(tokenUsageProvider.notifier).record(state.buffer.length ~/ 4);
  }

  void reset() => state = const StreamingState();
}

// ── TokenUsageProvider ───────────────────────────────────────────

final tokenUsageProvider =
    NotifierProvider<TokenUsageNotifier, TokenUsageSnapshot>(
  TokenUsageNotifier.new,
);

class TokenUsageNotifier extends Notifier<TokenUsageSnapshot> {
  @override
  TokenUsageSnapshot build() => const TokenUsageSnapshot();

  void record(int tokens) {
    state = state.add(tokens);
  }

  void resetSession() {
    state = TokenUsageSnapshot(totalTokens: state.totalTokens);
  }
}

/// Convenience: current streaming message as AIMessage.
AIMessage? streamingAsMessage(StreamingState streaming) {
  if (streaming.buffer.isEmpty) return null;
  return AIMessage(
    id: streaming.messageId ?? 'streaming',
    role: AIMessageRole.assistant,
    content: streaming.buffer,
    createdAt: DateTime.now(),
    status: streaming.isStreaming
        ? AIMessageStatus.streaming
        : AIMessageStatus.completed,
  );
}
