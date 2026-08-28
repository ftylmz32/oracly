/// OR chamber chrome under QualityLoopGate — keeps screen slim.
library;

import 'package:flutter/material.dart';

import '../../../ai/domain/models/ai_message.dart';
import '../../../premium/models/personalization_models.dart';
import '../../controllers/companion_controller.dart';
import '../../models/companion_state.dart';
import '../../models/or_session_presentation.dart';
import 'companion_or_chat_frame.dart';
import 'companion_or_presence.dart';
import 'companion_reference_conversation_guard.dart';
import 'companion_reference_or_shell.dart';
import 'companion_reference_voice_listener.dart';

class CompanionReferenceChamber extends StatelessWidget {
  const CompanionReferenceChamber({
    super.key,
    required this.personality,
    required this.presence,
    required this.session,
    required this.bootstrapping,
    required this.state,
    required this.controller,
    required this.start,
    required this.messages,
    required this.busy,
    required this.allowSpeak,
    required this.scrollController,
    required this.inputController,
    required this.onSelected,
    required this.name,
    required this.onSend,
    required this.onMicTap,
    required this.onMicCancel,
    required this.onPlusTap,
  });

  final AiPersonality personality;
  final CompanionOrPresence presence;
  final OrSessionPresentation session;
  final bool bootstrapping;
  final CompanionState state;
  final CompanionController controller;
  final bool start;
  final List<AIMessage> messages;
  final bool busy;
  final bool allowSpeak;
  final ScrollController scrollController;
  final TextEditingController inputController;
  final ValueChanged<String> onSelected;
  final String name;
  final VoidCallback onSend;
  final VoidCallback? onMicTap;
  final VoidCallback? onMicCancel;
  final VoidCallback? onPlusTap;

  @override
  Widget build(BuildContext context) {
    return CompanionOrChatFrame(
      personality: personality,
      presence: presence,
      child: CompanionReferenceConversationGuard(
        child: CompanionReferenceVoiceListener(
          composer: inputController,
          child: SafeArea(
            bottom: false,
            child: CompanionReferenceOrShell(
              session: session,
              presence: presence,
              bootstrapping: bootstrapping,
              state: state,
              controller: controller,
              start: start,
              messages: messages,
              busy: busy,
              allowSpeak: allowSpeak,
              scrollController: scrollController,
              onSelected: onSelected,
              name: name,
              personality: personality.name,
              inputController: inputController,
              onSend: onSend,
              onMicTap: onMicTap,
              onMicCancel: onMicCancel,
              onPlusTap: onPlusTap,
            ),
          ),
        ),
      ),
    );
  }
}
