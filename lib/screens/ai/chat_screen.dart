import 'package:flutter/material.dart';

import '../../core/copy/conversation_copy.dart';
import '../../core/copy/resilience_copy.dart';
import '../../core/copy/transparency_copy.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/transparency_footnote.dart';
import '../../features/ai/presentation/widgets/conversation_closing_whisper.dart';
import '../../features/ai/presentation/widgets/thinking_animation.dart';
import '../../services/ai_service.dart';
import '../../services/memory_extractor.dart';
import '../../services/profile_service.dart';
import '../../services/storage_service.dart';
import '../../shared/ui/oracly_snackbar.dart';
import '../../shared/widgets/oracly_skeleton_loader.dart';
import '../../widgets/chat_input.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/oracly_icon.dart';
import '../../widgets/oracly_scaffold.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AiService _aiService = AiService();
  final MemoryExtractor _memoryExtractor = MemoryExtractor();
  final StorageService _storageService = StorageService();
  final ProfileService _profileService = ProfileService();

  bool _isLoading = false;
  bool _isBootstrapping = true;
  String? _lastFailedMessage;
  List<Map<String, dynamic>> _messages = [];

  int get _assistantReplyCount =>
      _messages.where((m) => m['isUser'] == false).length;

  bool get _showClosingWhisper =>
      !_isLoading && !_isBootstrapping && _assistantReplyCount >= 2;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final savedMessages = await _storageService.loadMessages();
      if (!mounted) return;

      if (savedMessages.isNotEmpty) {
        setState(() {
          _messages = savedMessages;
          _isBootstrapping = false;
        });
        return;
      }

      final profile = await _profileService.getProfile();
      if (!mounted) return;

      setState(() {
        _messages = [
          {
            'text': ConversationCopy.welcome(
              name: profile['name']?.toString(),
            ),
            'isUser': false,
          },
        ];
        _isBootstrapping = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isBootstrapping = false);
      OraclySnackBar.error(context, ResilienceCopy.aiUnavailable);
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'text': text, 'isUser': true});
      _isLoading = true;
      _lastFailedMessage = null;
    });

    _controller.clear();
    await _storageService.saveMessages(_messages);
    _scrollToBottom();

    try {
      await _memoryExtractor.analyzeMessage(text);
    } catch (_) {
      // Memory extraction is best-effort — never block the conversation.
    }

    final result = await _aiService.sendMessage(text);
    if (!mounted) return;

    if (!result.isSuccess) {
      setState(() {
        _isLoading = false;
        _lastFailedMessage = text;
      });
      OraclySnackBar.error(
        context,
        result.errorMessage ?? ResilienceCopy.aiUnavailable,
        action: SnackBarAction(
          label: ResilienceCopy.retryAction,
          onPressed: () {
            _controller.text = _lastFailedMessage ?? '';
            if (_lastFailedMessage != null) {
              _sendMessage();
            }
          },
        ),
      );
      return;
    }

    setState(() {
      _messages.add({'text': result.content!, 'isUser': false});
      _isLoading = false;
      _lastFailedMessage = null;
    });

    await _storageService.saveMessages(_messages);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: AppDuration.scroll,
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OraclyScaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.card,
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
              ),
              child: Center(
                child: OraclyIcon(Icons.auto_awesome, size: 18),
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OR',
                  style: AppTextStyles.title.copyWith(fontSize: 17),
                ),
                Text(
                  ConversationCopy.companionSubtitle,
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isBootstrapping
                ? OraclySkeletonLoader(message: ResilienceCopy.chatLoading)
                : ListView.builder(
                    controller: _scrollController,
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
                    itemCount:
                        _messages.length + (_showClosingWhisper ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_showClosingWhisper && index == _messages.length) {
                        return const ConversationClosingWhisper();
                      }

                      final message = _messages[index];
                      return RepaintBoundary(
                        key: ValueKey('chat-$index'),
                        child: MessageBubble(
                          message: message['text'] as String,
                          isUser: message['isUser'] as bool,
                          animate: index == _messages.length - 1,
                        ),
                      );
                    },
                  ),
          ),
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Semantics(
                liveRegion: true,
                label: ConversationCopy.thinkingLabel,
                child: Center(
                  child: ThinkingAnimation(
                    label: ConversationCopy.thinkingLabel,
                  ),
                ),
              ),
            ),
          const TransparencyFootnote(
            text: TransparencyCopy.conversationCaption,
          ),
          ChatInput(
            controller: _controller,
            onSend: _sendMessage,
            enabled: !_isLoading && !_isBootstrapping,
          ),
        ],
      ),
    );
  }
}
