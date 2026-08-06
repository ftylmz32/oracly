/// OR-1190 — Mystical oracle conversation after tarot reading.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/copy/conversation_copy.dart';
import '../../../../core/copy/transparency_copy.dart';
import '../../../../shared/ui/oracly_snackbar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/craftsmanship_rhythm.dart';
import '../../../../core/widgets/transparency_footnote.dart';
import '../../../../widgets/cosmic_background.dart';
import '../../domain/models/ai_message.dart';
import '../../oracle_conversation/models/oracle_reading_context.dart';
import '../../oracle_conversation/providers/oracle_conversation_providers.dart';
import '../widgets/conversation_closing_whisper.dart';
import '../widgets/conversation_message_entrance.dart';
import '../widgets/ai_message_bubble.dart';
import '../widgets/ai_typing_indicator.dart';
import '../widgets/oracle_conversation_empty_state.dart';
import '../widgets/oracle_conversation_header.dart';
import '../widgets/oracle_conversation_input.dart';
import '../widgets/oracle_message_actions_bar.dart';
import '../widgets/oracle_message_timestamp.dart';
import '../widgets/oracle_suggestion_chips.dart';

class OracleConversationScreen extends ConsumerStatefulWidget {
  const OracleConversationScreen({
    super.key,
    required this.readingContext,
  });

  final OracleReadingContext readingContext;

  @override
  ConsumerState<OracleConversationScreen> createState() =>
      _OracleConversationScreenState();
}

class _OracleConversationScreenState
    extends ConsumerState<OracleConversationScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: CraftsmanshipRhythm.scroll,
        curve: CraftsmanshipRhythm.curve,
      );
    });
  }

  Future<void> _send([String? preset]) async {
    final text = preset ?? _inputController.text;
    if (text.trim().isEmpty) return;

    _inputController.clear();
    FocusScope.of(context).unfocus();

    await ref
        .read(oracleConversationProvider(widget.readingContext).notifier)
        .send(text);
    _scrollToBottom();
  }

  void _onVoiceTap() {
    OraclySnackBar.show(
      context,
      message: 'Sesli soru yakında OR ile buluşacak.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(oracleConversationProvider(widget.readingContext));
    final favorites = ref.watch(oracleMessageFavoritesProvider);
    final busy = state.isThinking || state.isStreaming;

    ref.listen(oracleConversationProvider(widget.readingContext), (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        OraclySnackBar.error(context, next.error!);
        ref
            .read(oracleConversationProvider(widget.readingContext).notifier)
            .clearError();
      }
      _scrollToBottom();
    });

    final messages = state.conversation?.messages ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CosmicBackground(
        showParticles: false,
        child: Column(
          children: [
            OracleConversationHeader(
              context: widget.readingContext,
            ),
            Expanded(
              child: _MessageList(
                scrollController: _scrollController,
                messages: messages,
                showEmpty: state.showSuggestions,
                isThinking: state.isThinking,
                isStreaming: state.isStreaming,
                streamBuffer: state.streamBuffer,
                streamMessageId: state.streamMessageId,
                favorites: favorites,
                showClosing: messages.where((m) => m.isAssistant).length >= 2 && !busy,
                onRegenerate: (id) => ref
                    .read(
                      oracleConversationProvider(widget.readingContext)
                          .notifier,
                    )
                    .regenerate(id),
                onToggleFavorite: (id) =>
                    ref.read(oracleMessageFavoritesProvider.notifier).toggle(id),
              ),
            ),
            if (state.showSuggestions) ...[
              SizedBox(height: AppSpacing.sm),
              OracleSuggestionChipsRow(
                enabled: !busy,
                onSelected: _send,
              ),
              SizedBox(height: AppSpacing.sm),
            ],
            const TransparencyFootnote(
              text: TransparencyCopy.conversationCaption,
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
            ),
            OracleConversationInput(
              controller: _inputController,
              enabled: !busy,
              onSend: () => _send(),
              onVoiceTap: _onVoiceTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.scrollController,
    required this.messages,
    required this.showEmpty,
    required this.isThinking,
    required this.isStreaming,
    required this.streamBuffer,
    required this.streamMessageId,
    required this.favorites,
    required this.showClosing,
    required this.onRegenerate,
    required this.onToggleFavorite,
  });

  final ScrollController scrollController;
  final List<AIMessage> messages;
  final bool showEmpty;
  final bool isThinking;
  final bool isStreaming;
  final String streamBuffer;
  final String? streamMessageId;
  final Set<String> favorites;
  final bool showClosing;
  final void Function(String messageId) onRegenerate;
  final void Function(String messageId) onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final itemCount = messages.length +
        (isStreaming && streamBuffer.isNotEmpty ? 1 : 0) +
        (isThinking ? 1 : 0) +
        (showEmpty ? 1 : 0) +
        (showClosing ? 1 : 0);

    if (itemCount == 0) {
      return const Center(child: OracleConversationEmptyState());
    }

    return ListView.builder(
      controller: scrollController,
      cacheExtent: 600,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.lg,
      ),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (showEmpty && index == 0) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: OracleConversationEmptyState(),
          );
        }

        var msgIndex = showEmpty ? index - 1 : index;

        if (msgIndex < messages.length) {
          final message = messages[msgIndex];
          final isLatest = msgIndex == messages.length - 1 && !isStreaming && !isThinking;
          final row = _MessageRow(
            message: message,
            isFavorite: favorites.contains(message.id),
            onRegenerate: message.isAssistant
                ? () => onRegenerate(message.id)
                : null,
            onToggleFavorite: message.isAssistant
                ? () => onToggleFavorite(message.id)
                : null,
          );
          if (isLatest) {
            return RepaintBoundary(
              key: ValueKey(message.id),
              child: ConversationMessageEntrance(child: row),
            );
          }
          return RepaintBoundary(
            key: ValueKey(message.id),
            child: row,
          );
        }

        msgIndex -= messages.length;

        if (isStreaming && streamBuffer.isNotEmpty && msgIndex == 0) {
          final streamingMessage = AIMessage(
            id: streamMessageId ?? 'streaming',
            role: AIMessageRole.assistant,
            content: streamBuffer,
            createdAt: DateTime.now(),
            status: AIMessageStatus.streaming,
          );
          return AIMessageBubble(
            message: streamingMessage,
            showAvatar: true,
            useMarkdown: true,
          );
        }

        if (isThinking) {
          return Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AITypingIndicator(),
                SizedBox(height: AppSpacing.sm),
                Text(
                  ConversationCopy.oracleThinkingLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ],
            ),
          );
        }

        if (showClosing) {
          return const ConversationClosingWhisper();
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({
    required this.message,
    required this.isFavorite,
    this.onRegenerate,
    this.onToggleFavorite,
  });

  final AIMessage message;
  final bool isFavorite;
  final VoidCallback? onRegenerate;
  final VoidCallback? onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: message.isUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        AIMessageBubble(
          message: message,
          showAvatar: true,
          useMarkdown: !message.isUser,
          onRegenerate: null,
        ),
        if (message.isAssistant && message.status == AIMessageStatus.completed)
          Padding(
            padding: EdgeInsets.only(left: AppSpacing.xl + AppSpacing.sm),
            child: OracleMessageActionsBar(
              message: message,
              isFavorite: isFavorite,
              onRegenerate: onRegenerate,
              onToggleFavorite: onToggleFavorite,
            ),
          ),
        OracleMessageTimestamp(
          time: message.createdAt,
          alignEnd: message.isUser,
        ),
      ],
    );
  }
}
