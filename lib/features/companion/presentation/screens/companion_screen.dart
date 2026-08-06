/// SPRINT-003 — ORACLY permanent AI companion tab.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/copy/conversation_copy.dart';
import '../../../../core/copy/resilience_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/craftsmanship_rhythm.dart';
import '../../../../core/widgets/transparency_footnote.dart';
import '../../../ai/presentation/widgets/ai_message_bubble.dart';
import '../../../ai/presentation/widgets/ai_typing_indicator.dart';
import '../../../ai/presentation/widgets/conversation_closing_whisper.dart';
import '../../../ai/presentation/widgets/conversation_message_entrance.dart';
import '../../../ai/presentation/widgets/oracle_conversation_input.dart';
import '../../../../core/navigation/oracly_navigation_service.dart';
import '../../../../shared/ui/oracly_snackbar.dart';
import '../../../../widgets/cosmic_background.dart';
import '../../controllers/companion_controller.dart';
import '../../copy/companion_copy.dart';
import '../../models/companion_state.dart';
import '../../providers/companion_providers.dart';
import '../widgets/companion_header.dart';
import '../widgets/companion_suggestion_chips.dart';

class CompanionScreen extends ConsumerStatefulWidget {
  const CompanionScreen({super.key});

  @override
  ConsumerState<CompanionScreen> createState() => _CompanionScreenState();
}

class _CompanionScreenState extends ConsumerState<CompanionScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

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

    await ref.read(companionControllerProvider).send(text);
    _scrollToBottom();
  }

  void _openMemories() {
    OraclyNavigationService.openMemory(context);
  }

  void _onVoiceTap() {
    OraclySnackBar.show(context, message: CompanionCopy.voiceComingSoon);
  }

  Future<void> _saveLastUserMessage(CompanionController controller) async {
    final conversation = controller.state.conversation;
    if (conversation == null) return;
    final lastUser = conversation.messages.where((m) => m.isUser).lastOrNull;
    if (lastUser == null) return;
    await controller.saveToMemory(lastUser.content);
    if (mounted) {
      OraclySnackBar.show(context, message: CompanionCopy.memorySaved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(companionControllerProvider);
    final state = controller.state;
    final busy = state.isBusy || state.phase == CompanionPhase.thinking;

    ref.listen(companionControllerProvider, (_, __) => _scrollToBottom());

    final assistantCount = state.conversation?.messages
            .where((m) => m.isAssistant)
            .length ??
        0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CosmicBackground(
        child: SafeArea(
          child: Column(
            children: [
              CompanionHeader(
                subtitle: ConversationCopy.companionSubtitle,
                onMemoryTap: _openMemories,
              ),
              Expanded(
                child: switch (state.phase) {
                  CompanionPhase.error =>
                    _ErrorBody(message: state.errorMessage),
                  _ => _ConversationBody(
                      state: state,
                      scrollController: _scrollController,
                      onSaveMemory: () => _saveLastUserMessage(controller),
                    ),
                },
              ),
              if (state.phase != CompanionPhase.error) ...[
                if (assistantCount <= 1 && !busy)
                  CompanionSuggestionChips(
                    suggestions: CompanionCopy.suggestions,
                    onSelected: _send,
                  ),
                if (busy)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: const AITypingIndicator(),
                  ),
                OracleConversationInput(
                  controller: _inputController,
                  onSend: () => _send(),
                  enabled: !busy,
                  onVoiceTap: _onVoiceTap,
                ),
                Padding(
                  padding: AppSpacing.screenHorizontal.copyWith(
                    bottom: AppSpacing.sm,
                  ),
                  child: Column(
                    children: [
                      TransparencyFootnote(
                        text: CompanionCopy.memoryTransparency,
                      ),
                      if (assistantCount >= 2 && !busy)
                        const ConversationClosingWhisper(),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationBody extends StatelessWidget {
  const _ConversationBody({
    required this.state,
    required this.scrollController,
    required this.onSaveMemory,
  });

  final CompanionState state;
  final ScrollController scrollController;
  final VoidCallback onSaveMemory;

  @override
  Widget build(BuildContext context) {
    final messages = state.conversation?.messages ?? const [];

    if (messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      padding: AppSpacing.screenHorizontal.copyWith(
        top: AppSpacing.sm,
        bottom: AppSpacing.md,
      ),
      cacheExtent: 600,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return ConversationMessageEntrance(
          key: ValueKey(message.id),
          child: Column(
            crossAxisAlignment: message.isUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              AIMessageBubble(message: message),
              if (message.isUser && index == messages.length - 2)
                TextButton(
                  onPressed: onSaveMemory,
                  child: Text(
                    CompanionCopy.saveToMemory,
                    style: TextStyle(
                      color: AppColors.gold.withValues(alpha: 0.75),
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenHorizontal,
        child: Text(
          message ?? ResilienceCopy.aiUnavailable,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

extension _LastOrNull<E> on Iterable<E> {
  E? get lastOrNull {
    if (isEmpty) return null;
    return last;
  }
}
