/// OR-1190 — Riverpod providers for oracle conversation.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/copy/resilience_copy.dart';
import '../../domain/models/ai_conversation.dart';
import '../../domain/models/ai_message.dart';
import '../../services/conversation_memory.dart';
import '../models/oracle_reading_context.dart';
import '../repositories/oracle_conversation_repository.dart';

final oracleConversationMemoryProvider = Provider<ConversationMemory>((ref) {
  return ConversationMemory();
});

final oracleConversationRepositoryProvider =
    Provider<MockOracleConversationRepository>((ref) {
  return MockOracleConversationRepository(
    memory: ref.watch(oracleConversationMemoryProvider),
  );
});

final oracleMessageFavoritesProvider =
    NotifierProvider<OracleMessageFavoritesNotifier, Set<String>>(
  OracleMessageFavoritesNotifier.new,
);

class OracleMessageFavoritesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void toggle(String messageId) {
    final next = Set<String>.from(state);
    if (next.contains(messageId)) {
      next.remove(messageId);
    } else {
      next.add(messageId);
    }
    state = next;
  }

  bool isFavorite(String messageId) => state.contains(messageId);
}

final oracleConversationProvider = NotifierProvider.family<
    OracleConversationNotifier, OracleConversationState, OracleReadingContext>(
  OracleConversationNotifier.new,
);

@immutable
class OracleConversationState {
  const OracleConversationState({
    this.conversation,
    this.isThinking = false,
    this.isStreaming = false,
    this.streamBuffer = '',
    this.streamMessageId,
    this.error,
  });

  final AIConversation? conversation;
  final bool isThinking;
  final bool isStreaming;
  final String streamBuffer;
  final String? streamMessageId;
  final String? error;

  bool get hasMessages =>
      (conversation?.messages.isNotEmpty ?? false) || streamBuffer.isNotEmpty;

  bool get showSuggestions =>
      !hasMessages && !isThinking && !isStreaming;

  OracleConversationState copyWith({
    AIConversation? conversation,
    bool? isThinking,
    bool? isStreaming,
    String? streamBuffer,
    String? streamMessageId,
    String? error,
    bool clearStream = false,
    bool clearError = false,
  }) {
    return OracleConversationState(
      conversation: conversation ?? this.conversation,
      isThinking: isThinking ?? this.isThinking,
      isStreaming: isStreaming ?? this.isStreaming,
      streamBuffer: clearStream ? '' : (streamBuffer ?? this.streamBuffer),
      streamMessageId:
          clearStream ? null : (streamMessageId ?? this.streamMessageId),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class OracleConversationNotifier
    extends FamilyNotifier<OracleConversationState, OracleReadingContext> {
  late OracleReadingContext _context;

  @override
  OracleConversationState build(OracleReadingContext arg) {
    _context = arg;
    _initConversation();
    return const OracleConversationState();
  }

  Future<void> _initConversation() async {
    final repo = ref.read(oracleConversationRepositoryProvider);
    final conv = await repo.startConversation(_context);
    state = state.copyWith(conversation: conv);
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final conv = state.conversation;
    if (conv == null || state.isStreaming || state.isThinking) return;

    final repo = ref.read(oracleConversationRepositoryProvider);
    final streamId = 'stream_${DateTime.now().millisecondsSinceEpoch}';

    state = state.copyWith(
      isThinking: true,
      error: null,
      clearStream: true,
    );

    await Future<void>.delayed(const Duration(milliseconds: 280));

    state = state.copyWith(
      isThinking: false,
      isStreaming: true,
      streamMessageId: streamId,
    );

    var buffer = '';
    try {
      await for (final chunk in repo.streamMessage(
        conversationId: conv.id,
        userMessage: trimmed,
        context: _context,
      )) {
        buffer += chunk;
        state = state.copyWith(streamBuffer: buffer);
      }

      final assistant = AIMessage(
        id: 'msg_a_${DateTime.now().millisecondsSinceEpoch}',
        role: AIMessageRole.assistant,
        content: buffer,
        createdAt: DateTime.now(),
        status: AIMessageStatus.completed,
        tokenCount: buffer.length ~/ 4,
      );
      ref.read(oracleConversationMemoryProvider).appendMessage(
            conv.id,
            assistant,
          );

      final updated = await repo.getConversation(conv.id);
      state = state.copyWith(
        conversation: updated,
        isStreaming: false,
        clearStream: true,
      );
    } catch (e) {
      state = state.copyWith(
        isThinking: false,
        isStreaming: false,
        error: ResilienceCopy.oracleSendFailed,
        clearStream: true,
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> regenerate(String messageId) async {
    final conv = state.conversation;
    if (conv == null || state.isStreaming) return;

    state = state.copyWith(isThinking: true, error: null);
    try {
      final repo = ref.read(oracleConversationRepositoryProvider);
      await repo.regenerateMessage(
        conversationId: conv.id,
        messageId: messageId,
        context: _context,
      );
      final updated = await repo.getConversation(conv.id);
      state = state.copyWith(conversation: updated, isThinking: false);
    } catch (_) {
      state = state.copyWith(
        isThinking: false,
        error: ResilienceCopy.oracleRegenerateFailed,
      );
    }
  }
}
