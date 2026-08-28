/// OR main pane — free preview, idle invitation, or live thread.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ai/domain/models/ai_message.dart';
import '../../controllers/companion_controller.dart';
import '../../models/companion_state.dart';
import '../../providers/companion_providers.dart';
import '../../services/or_chat_handoff.dart';
import 'companion_reference_idle.dart';
import 'companion_reference_or_premium_preview.dart';
import 'companion_reference_thread.dart';

class CompanionReferenceOrBody extends ConsumerWidget {
  const CompanionReferenceOrBody({
    super.key,
    required this.canChat,
    required this.start,
    required this.bootstrapping,
    required this.messages,
    required this.busy,
    required this.state,
    required this.allowSpeak,
    required this.controller,
    required this.scrollController,
    required this.onSelected,
    required this.name,
    required this.personality,
  });

  final bool canChat;
  final bool start;
  final bool bootstrapping;
  final List<AIMessage> messages;
  final bool busy;
  final CompanionState state;
  final bool allowSpeak;
  final CompanionController controller;
  final ScrollController scrollController;
  final ValueChanged<String> onSelected;
  final String name;
  final String personality;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!canChat && (start || messages.isEmpty)) {
      return CompanionReferenceOrPremiumPreview(personality: personality);
    }
    if (start || (bootstrapping && messages.isEmpty)) {
      final reading = controller.readingContext;
      return CompanionReferenceIdle(
        onSelected: onSelected,
        userName: name,
        personality: personality,
        kindId: reading?.kind.name,
        contextLine: reading == null
            ? null
            : OrChatHandoff.arrivalLine(reading),
      );
    }
    return CompanionReferenceThread(
      scrollController: scrollController,
      messages: messages,
      showActions: canChat && !busy && state.errorMessage == null,
      allowSpeak: allowSpeak,
      hasReadingContext: controller.readingContext != null,
      onSpeak: (text) =>
          ref.read(companionOutputControllerProvider).speakNow(text),
      onRegenerate: () {
        if (!canChat) return;
        controller.regenerateLast();
      },
      onFollowUp: canChat ? onSelected : null,
    );
  }
}
