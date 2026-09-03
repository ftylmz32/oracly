/// Conversation list — human turns, useful actions, calm scroll.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/revisit/providers/discovery_revisit_provider.dart';
import '../../../ai/domain/models/ai_message.dart';
import 'companion_new_reply_chip.dart';
import 'companion_reference_actions.dart';
import 'companion_reference_thread_list.dart';
import 'companion_reference_thread_visible.dart';

export 'companion_reference_thread_visible.dart';

class CompanionReferenceThread extends ConsumerStatefulWidget {
  const CompanionReferenceThread({
    super.key,
    required this.scrollController,
    required this.messages,
    required this.showActions,
    required this.onSpeak,
    required this.onRegenerate,
    this.allowSpeak = false,
    this.onFollowUp,
    this.hasReadingContext = false,
  });

  final ScrollController scrollController;
  final List<AIMessage> messages;
  final bool showActions;
  final ValueChanged<String> onSpeak;
  final VoidCallback onRegenerate;
  final bool allowSpeak;
  final ValueChanged<String>? onFollowUp;
  final bool hasReadingContext;

  @override
  ConsumerState<CompanionReferenceThread> createState() =>
      _CompanionReferenceThreadState();
}

class _CompanionReferenceThreadState
    extends ConsumerState<CompanionReferenceThread> {
  bool _showNewReply = false;
  int _seenCount = 0;
  String _visibleSig = '';
  List<AIMessage> _visible = const [];

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
    _visible = _cacheVisible(widget.messages);
    _seenCount = _visible.length;
    if (_visible.isNotEmpty) {
      // A restored conversation has no previous scroll position. Wait until
      // both the list and the persistent lower dock have completed layout,
      // then reveal the newest complete turn.
      restoreCompanionThreadToBottom(widget.scrollController);
    }
  }

  @override
  void didUpdateWidget(CompanionReferenceThread oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_onScroll);
      widget.scrollController.addListener(_onScroll);
    }
    // Capture this before the longer list changes maxScrollExtent. Checking
    // after layout incorrectly makes a user who was at the bottom look far
    // away from it and leaves the newest assistant turn behind the dock.
    final wasNearBottom = isCompanionThreadNearBottom(widget.scrollController);
    final next = _cacheVisible(widget.messages);
    if (next.length <= _seenCount) return;
    final grew = next.length - _seenCount;
    _seenCount = next.length;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (wasNearBottom) {
        forceScrollCompanionThread(widget.scrollController);
        if (_showNewReply) setState(() => _showNewReply = false);
      } else if (grew > 0) {
        setState(() => _showNewReply = true);
      }
    });
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (!_showNewReply) return;
    if (isCompanionThreadNearBottom(widget.scrollController)) {
      setState(() => _showNewReply = false);
    }
  }

  List<AIMessage> _cacheVisible(List<AIMessage> messages) {
    final sig = companionVisibleSignature(messages);
    if (sig == _visibleSig) return _visible;
    _visibleSig = sig;
    _visible = companionVisibleMessages(messages);
    return _visible;
  }

  @override
  Widget build(BuildContext context) {
    final revisit = ref.watch(discoveryRevisitOfferProvider);
    final visible = _cacheVisible(widget.messages);
    final lastOrId = visible.isNotEmpty && visible.last.isAssistant
        ? visible.last.id
        : null;
    final lastUser = visible.reversed
        .where((m) => m.isUser)
        .map((m) => m.content)
        .firstOrNull;
    return Stack(
      children: [
        CompanionReferenceThreadList(
          scrollController: widget.scrollController,
          visible: visible,
          lastOrId: lastOrId,
          showActions: widget.showActions,
          onSpeak: widget.onSpeak,
          onRegenerate: widget.onRegenerate,
          allowSpeak: widget.allowSpeak,
          revisit: revisit,
          onFollowUp: widget.onFollowUp,
          hasReadingContext: widget.hasReadingContext,
          lastUserMessage: lastUser ?? '',
        ),
        if (_showNewReply)
          Positioned(
            left: 0,
            right: 0,
            bottom: 10,
            child: Center(
              child: CompanionNewReplyChip(
                onTap: () {
                  setState(() => _showNewReply = false);
                  forceScrollCompanionThread(widget.scrollController);
                },
              ),
            ),
          ),
      ],
    );
  }
}
