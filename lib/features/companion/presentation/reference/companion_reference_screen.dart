/// OR chat — conversation-first shell over the live companion path.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../core/quality/quality_feature.dart';
import '../../../../core/voice/oracly_proxy_speech.dart';
import '../../../../core/voice/oracly_tts_gate.dart';
import '../../../premium/models/personalization_models.dart';
import '../../../premium/providers/premium_providers.dart';
import '../../../quality_loop/widgets/quality_loop_gate.dart';
import '../../models/companion_state.dart';
import '../../providers/companion_providers.dart';
import '../../services/companion_or_conversation_access.dart';
import '../../services/first_reading_or_deepen.dart';
import '../../services/or_chat_handoff.dart';
import '../../services/or_context_bucket_helpers.dart';
import '../../services/or_session_resolver.dart';
import 'companion_or_presence.dart';
import 'companion_reference_actions.dart';
import 'companion_reference_chamber.dart';
import 'companion_reference_plus_sheet.dart';

class CompanionReferenceScreen extends ConsumerStatefulWidget {
  const CompanionReferenceScreen({super.key});

  @override
  ConsumerState<CompanionReferenceScreen> createState() =>
      _CompanionReferenceScreenState();
}

class _CompanionReferenceScreenState
    extends ConsumerState<CompanionReferenceScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _openedLogged = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _openedLogged) return;
      _openedLogged = true;
      ref.read(analyticsServiceProvider).logScreenView('or');
      ref.read(premiumStatusProvider).load();
      final handoff = OrChatHandoffBuffer.take();
      if (handoff != null) {
        ref.read(companionControllerProvider).applyReadingHandoff(handoff);
      }
      ref.read(companionVoiceTurnControllerProvider).bindSender((text) async {
        _inputController.text = text;
        await _send(text);
        if (mounted) _inputController.clear();
      });
    });
  }

  @override
  void dispose() {
    OraclyTtsGate.interrupt();
    OraclyProxySpeech.releaseCaches();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onMic() => toggleCompanionMic(
    context: context,
    ref: ref,
    composer: _inputController,
  );

  Future<void> _onMicCancel() => cancelCompanionMic(ref: ref);

  Future<void> _send([String? preset]) => sendCompanionComposer(
    ref: ref,
    context: context,
    composer: _inputController,
    preset: preset,
    onScrolled: () => scrollCompanionThread(_scrollController),
  );

  void _onPlus() {
    final reading = ref.read(companionControllerProvider).readingContext;
    if (!CompanionOrConversationAccess.ensure(
      context,
      readingContext: reading,
    )) {
      return;
    }
    showCompanionPromptSheet(context: context, onSelected: _send);
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(companionControllerProvider);
    final output = ref.watch(companionOutputControllerProvider);
    final speaking = output.isSpeaking;
    final voiceMode = output.isVoice;
    final voiceUnavailable = output.voiceUnavailable;
    final entitlement = CompanionOrConversationAccess.watch(ref);
    final state = controller.state;
    final busy = state.isBusy || state.phase == CompanionPhase.thinking;
    final bootstrapping = state.phase == CompanionPhase.initializing;
    final messages = state.conversation?.messages ?? const [];
    final handoffHeld = OrContextBucketHelpers.looksFeature(
      state.context?.proactiveAcknowledgment ?? '',
    );
    final start = !busy && !messages.any((m) => m.isUser) && !handoffHeld;
    final deepen = FirstReadingOrDeepen.allows(
      ref.watch(localStorageProvider),
      controller.readingContext,
    );
    final session = OrSessionResolver.resolve(
      entitlement: entitlement,
      link: state.linkStatus,
      lastFailure: state.lastFailureKind,
      voiceUnavailable: voiceUnavailable,
      bootstrapping: bootstrapping,
      chamberEmpty: start || messages.isEmpty,
      busy: busy,
      networkRetry: controller.isNetworkRetrying,
      contextualDeepenAllowed: deepen,
    );
    final presence = CompanionOrPresenceResolve.from(
      phase: state.phase,
      busy: busy,
      speaking: speaking,
      voiceMode: voiceMode,
    );
    final personality =
        ref.watch(settingsProvider).value?.aiPersonality ??
        AiPersonality.mystical;
    final name = ref.watch(userProfileProvider).value?.name ?? '';
    return QualityLoopGate(
      feature: QualityFeature.companion,
      startOnInit: true,
      child: CompanionReferenceChamber(
        personality: personality,
        presence: presence,
        session: session,
        bootstrapping: bootstrapping,
        state: state,
        controller: controller,
        start: start,
        messages: messages,
        busy: busy,
        allowSpeak: session.canCompose && voiceMode,
        scrollController: _scrollController,
        inputController: _inputController,
        onSelected: _send,
        name: name,
        onSend: () => _send(),
        onMicTap: _onMic,
        onMicCancel: _onMicCancel,
        onPlusTap: _onPlus,
      ),
    );
  }
}
