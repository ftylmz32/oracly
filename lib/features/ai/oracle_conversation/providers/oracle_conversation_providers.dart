/// OR-1190 — Riverpod providers for oracle conversation.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/copy/ai_source_copy.dart';
import '../../../../core/copy/resilience_copy.dart';
import '../../../../core/voice/oracly_tts_gate.dart';
import '../../../oracle_core/services/oracle_or_style_hint.dart';
import '../../../personal_discovery/providers/personal_discovery_providers.dart';
import '../../domain/models/ai_conversation.dart';
import '../../domain/models/ai_message.dart';
import '../../production/ai_request_exception.dart';
import '../../production/oracly_ai_providers.dart';
import '../../services/conversation_memory.dart';
import '../models/oracle_reading_context.dart';
import '../repositories/oracle_conversation_repository.dart';
import '../services/oracle_ai_message_source.dart';

final oracleConversationMemoryProvider = Provider<ConversationMemory>((ref) {
  return ConversationMemory();
});

final oracleConversationRepositoryProvider =
    Provider<MockOracleConversationRepository>((ref) {
  return MockOracleConversationRepository(
    memory: ref.watch(oracleConversationMemoryProvider),
    source: OracleAiMessageSource(
      ai: ref.watch(oraclyAiServiceProvider),
      contextHintFor: (message) async {
        try {
          final profile = await ref
              .read(personalDiscoveryProfileProvider.future)
              .timeout(const Duration(seconds: 3));
          return OracleOrStyleHint.forMessage(profile, message);
        } catch (_) {
          // Continuity is optional. A slow/failed profile must never block OR.
          return null;
        }
      },
    ),
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
    this.lastFailedText,
  });

  final AIConversation? conversation;
  final bool isThinking;
  final bool isStreaming;
  final String streamBuffer;
  final String? streamMessageId;
  final String? error;
  final String? lastFailedText;

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
    String? lastFailedText,
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
      lastFailedText: lastFailedText ?? this.lastFailedText,
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

    await OraclyTtsGate.stop();

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

    final priorUser = conv.messages
        .where((m) => m.isUser)
        .map((m) => m.content)
        .toList();
    var buffer = '';
    try {
      await for (final chunk in repo.streamMessage(
        conversationId: conv.id,
        userMessage: trimmed,
        context: _context,
        priorUser: priorUser,
      )) {
        buffer += chunk;
        state = state.copyWith(streamBuffer: buffer);
      }
      if (buffer.trim().isEmpty) {
        throw StateError('empty-or-response');
      }

      final assistant = AIMessage(
        id: 'msg_a_${DateTime.now().millisecondsSinceEpoch}',
        role: AIMessageRole.assistant,
        content: buffer,
        createdAt: DateTime.now(),
        status: AIMessageStatus.completed,
        tokenCount: buffer.length ~/ 4,
        metadata: AiSourceCopy.tag(
          fromAi: ref.read(oraclyAiServiceProvider).isConfigured,
        ),
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
      await OraclyTtsGate.speakReply(buffer);
    } on AiRequestException catch (e) {
      state = state.copyWith(
        isThinking: false,
        isStreaming: false,
        error: e.userMessage,
        lastFailedText: trimmed,
        clearStream: true,
      );
    } catch (_) {
      state = state.copyWith(
        isThinking: false,
        isStreaming: false,
        error: ResilienceCopy.oracleSendFailed,
        lastFailedText: trimmed,
        clearStream: true,
      );
    }
  }

  Future<void> retryLast() async {
    final failed = state.lastFailedText?.trim() ?? '';
    if (failed.isEmpty) return;
    state = state.copyWith(clearError: true, lastFailedText: null);
    await send(failed);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> regenerate(String messageId) async {
    final conv = state.conversation;
    if (conv == null || state.isStreaming) return;

    await OraclyTtsGate.stop();
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
      String? spoken;
      for (final m in updated?.messages ?? const <AIMessage>[]) {
        if (m.id == messageId) {
          spoken = m.content;
          break;
        }
      }
      await OraclyTtsGate.speakReply(spoken);
    } on AiRequestException catch (e) {
      state = state.copyWith(
        isThinking: false,
        error: e.userMessage,
      );
    } catch (_) {
      state = state.copyWith(
        isThinking: false,
        error: ResilienceCopy.oracleRegenerateFailed,
      );
    }
  }
}
