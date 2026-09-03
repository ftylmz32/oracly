/// OR Rehberi composer actions — stop STT, then existing text send.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/ui/oracly_snackbar.dart';
import '../../../../shared/ui/oracly_permission_dialog.dart';
import '../../controllers/companion_controller.dart';
import '../../copy/companion_copy.dart';
import '../../services/companion_or_conversation_access.dart';
import '../../debug/or_runtime_log.dart';
import '../../providers/companion_providers.dart';
import '../../voice/or_voice_turn_phase.dart';
import '../../../personal_discovery/services/personal_discovery_refresh.dart';
import 'companion_reference_tokens.dart';

/// Start a one-shot capture, or stop the active one. Never continuous listen.
Future<void> toggleCompanionMic({
  required BuildContext context,
  required WidgetRef ref,
  required TextEditingController composer,
}) async {
  // Mic stays Premium-only — free deepen is text-only.
  if (!CompanionOrConversationAccess.ensurePremium(context)) return;
  final turn = ref.read(companionVoiceTurnControllerProvider);
  if (turn.isActive) {
    if (turn.phase == OrVoiceTurnPhase.listening || turn.isReady) {
      final allowed = turn.isReady
          ? await OraclyPermissionDialog.microphone(context)
          : true;
      if (allowed != true || !context.mounted) return;
      await turn.onMicTap();
    }
    return;
  }
  final voice = ref.read(companionVoiceControllerProvider);
  if (voice.isListening) {
    await voice.stop();
    return;
  }
  if (voice.isRequesting) return;
  final allowed = await OraclyPermissionDialog.microphone(context);
  if (allowed != true || !context.mounted) return;
  await voice.start(existingText: composer.text);
}

/// Discard the current capture and release the microphone.
Future<void> cancelCompanionMic({required WidgetRef ref}) async {
  final turn = ref.read(companionVoiceTurnControllerProvider);
  if (turn.isActive) {
    await turn.cancel();
    return;
  }
  await ref.read(companionVoiceControllerProvider).cancel();
}

/// After a graceful failure — one fresh capture, not continuous listening.
Future<void> retryCompanionMic({
  required BuildContext context,
  required WidgetRef ref,
  required TextEditingController composer,
}) async {
  final voice = ref.read(companionVoiceControllerProvider);
  if (voice.isActive) return;
  final allowed = await OraclyPermissionDialog.microphone(context);
  if (allowed != true || !context.mounted) return;
  await voice.retry(existingText: composer.text);
}

Future<void> sendCompanionComposer({
  required WidgetRef ref,
  required BuildContext context,
  required TextEditingController composer,
  String? preset,
  required VoidCallback onScrolled,
}) async {
  final session = ref.read(companionControllerProvider);
  if (!CompanionOrConversationAccess.ensure(
    context,
    readingContext: session.readingContext,
  )) {
    return;
  }
  final voice = ref.read(companionVoiceControllerProvider);
  if (voice.isActive) await voice.stop();
  if (!context.mounted) return;
  final text = preset ?? composer.text;
  if (text.trim().isEmpty) {
    logOrSubmit(
      textLength: 0,
      sessionReady: session.state.conversation != null,
      blocked: true,
    );
    return;
  }
  if (session.state.conversation == null) {
    await session.initialize();
    if (!context.mounted) return;
  }
  if (session.state.conversation == null) {
    logOrSubmit(
      textLength: text.trim().length,
      sessionReady: false,
      blocked: true,
    );
    return;
  }
  logOrSubmit(textLength: text.trim().length, sessionReady: true);
  composer.clear();
  voice.consumeTranscript();
  FocusScope.of(context).unfocus();
  await session.send(text);
  PersonalDiscoveryRefresh.invalidate(ref);
  if (!context.mounted) return;
  onScrolled();
}

void scrollCompanionThread(ScrollController controller) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!isCompanionThreadNearBottom(controller)) return;
    forceScrollCompanionThread(controller);
  });
}

bool isCompanionThreadNearBottom(ScrollController controller) {
  if (!controller.hasClients) return true;
  final position = controller.position;
  return position.pixels >=
      position.maxScrollExtent - CompanionReferenceTokens.nearBottomPx;
}

void forceScrollCompanionThread(ScrollController controller) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!controller.hasClients) return;
    controller.animateTo(
      controller.position.maxScrollExtent,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  });
}

void restoreCompanionThreadToBottom(ScrollController controller) {
  double? previousExtent;
  var stableFrames = 0;
  var remainingFrames = 12;

  void followMeasuredExtent(Duration _) {
    if (!controller.hasClients) return;
    final extent = controller.position.maxScrollExtent;
    controller.jumpTo(extent);

    if (previousExtent != null && (extent - previousExtent!).abs() < 0.5) {
      stableFrames++;
    } else {
      stableFrames = 0;
    }
    previousExtent = extent;
    remainingFrames--;
    if (stableFrames < 2 && remainingFrames > 0) {
      WidgetsBinding.instance.addPostFrameCallback(followMeasuredExtent);
      WidgetsBinding.instance.scheduleFrame();
    }
  }

  WidgetsBinding.instance.addPostFrameCallback(followMeasuredExtent);
}

Future<void> saveLastCompanionMemory({
  required BuildContext context,
  required CompanionController controller,
}) async {
  final conversation = controller.state.conversation;
  if (conversation == null) return;
  final users = conversation.messages.where((m) => m.isUser);
  if (users.isEmpty) return;
  await controller.saveToMemory(users.last.content);
  if (context.mounted) {
    OraclySnackBar.show(context, message: CompanionCopy.memorySaved);
  }
}
