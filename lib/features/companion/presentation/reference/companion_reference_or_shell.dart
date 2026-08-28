/// OR column chrome — app bar, strip, body, composer or Premium dock.
library;

import 'package:flutter/material.dart';

import '../../../ai/domain/models/ai_message.dart';
import '../../controllers/companion_controller.dart';
import '../../models/companion_state.dart';
import '../../models/or_session_presentation.dart';
import '../../services/or_chat_handoff.dart';
import 'companion_handoff_banner.dart';
import 'companion_or_presence.dart';
import 'companion_or_session_strip.dart';
import 'companion_reference_app_bar.dart';
import 'companion_reference_composer_dock.dart';
import 'companion_reference_or_body.dart';
import 'companion_reference_or_premium_dock.dart';
import 'companion_reference_tokens.dart';

class CompanionReferenceOrShell extends StatelessWidget {
  const CompanionReferenceOrShell({
    super.key,
    required this.session,
    required this.presence,
    required this.bootstrapping,
    required this.state,
    required this.controller,
    required this.start,
    required this.messages,
    required this.busy,
    required this.allowSpeak,
    required this.scrollController,
    required this.onSelected,
    required this.name,
    required this.personality,
    required this.inputController,
    required this.onSend,
    required this.onMicTap,
    required this.onMicCancel,
    required this.onPlusTap,
  });

  final OrSessionPresentation session;
  final CompanionOrPresence presence;
  final bool bootstrapping;
  final CompanionState state;
  final CompanionController controller;
  final bool start;
  final List<AIMessage> messages;
  final bool busy;
  final bool allowSpeak;
  final ScrollController scrollController;
  final ValueChanged<String> onSelected;
  final String name;
  final String personality;
  final TextEditingController inputController;
  final VoidCallback onSend;
  final VoidCallback? onMicTap;
  final VoidCallback? onMicCancel;
  final VoidCallback? onPlusTap;

  @override
  Widget build(BuildContext context) {
    final reading = controller.readingContext;
    final arrival =
        reading == null ? null : OrChatHandoff.arrivalLine(reading);
    final handoff = CompanionHandoffBanner.of(
      state.context?.proactiveAcknowledgment,
    );
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            CompanionReferenceTokens.screenHorizontal,
            CompanionReferenceTokens.screenTop,
            CompanionReferenceTokens.screenHorizontal,
            0,
          ),
          child: CompanionReferenceAppBar(
            onBack: () => Navigator.maybePop(context),
            presence: presence,
          ),
        ),
        CompanionOrSessionStrip(
          presentation: session,
          onRetry: session.canRetry ? () => controller.retryLast() : null,
        ),
        if (arrival != null)
          CompanionHandoffBanner.contextOnly(arrival)
        else if (handoff != null)
          CompanionHandoffBanner(compact: handoff),
        Expanded(
          child: CompanionReferenceOrBody(
            canChat: session.canCompose,
            start: start,
            bootstrapping: bootstrapping,
            messages: messages,
            busy: busy,
            state: state,
            allowSpeak: allowSpeak,
            controller: controller,
            scrollController: scrollController,
            onSelected: onSelected,
            name: name,
            personality: personality,
          ),
        ),
        // Soft-cap dock on short/keyboard canvases — never clip CTAs or mic.
        if (session.canCompose)
          Flexible(
            fit: FlexFit.loose,
            child: SingleChildScrollView(
              reverse: true,
              physics: const ClampingScrollPhysics(),
              child: CompanionReferenceComposerDock(
                inputController: inputController,
                onSend: onSend,
                enabled: !busy,
                busy: busy,
                errorMessage: (!busy && state.errorMessage != null)
                    ? state.errorMessage
                    : null,
                onRetry: () => controller.retryLast(),
                onMicTap: session.canUseMic ? onMicTap : null,
                onMicCancel: onMicCancel,
                onPlusTap: onPlusTap,
              ),
            ),
          )
        else if (session.showPaywallDock)
          Flexible(
            fit: FlexFit.loose,
            child: SingleChildScrollView(
              reverse: true,
              physics: const ClampingScrollPhysics(),
              child: const CompanionReferenceOrPremiumDock(),
            ),
          ),
      ],
    );
  }
}
