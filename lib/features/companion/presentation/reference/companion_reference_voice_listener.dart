/// Keeps composer in sync with voice settle — not while live listening.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/companion_voice_controller.dart';
import '../../providers/companion_providers.dart';
import '../../voice/companion_voice_phase.dart';

class CompanionReferenceVoiceListener extends ConsumerStatefulWidget {
  const CompanionReferenceVoiceListener({
    super.key,
    required this.composer,
    required this.child,
  });

  final TextEditingController composer;
  final Widget child;

  @override
  ConsumerState<CompanionReferenceVoiceListener> createState() =>
      _CompanionReferenceVoiceListenerState();
}

class _CompanionReferenceVoiceListenerState
    extends ConsumerState<CompanionReferenceVoiceListener> {
  CompanionVoiceController? _voice;
  bool _wasListening = false;

  @override
  void dispose() {
    _voice?.removeListener(_onVoice);
    super.dispose();
  }

  void _bind(CompanionVoiceController voice) {
    if (identical(_voice, voice)) return;
    _voice?.removeListener(_onVoice);
    _voice = voice;
    voice.addListener(_onVoice);
  }

  void _onVoice() {
    final voice = _voice;
    if (voice == null) return;
    final phase = voice.phase;
    final listening = phase == CompanionVoicePhase.listening ||
        phase == CompanionVoicePhase.requesting;
    if (_wasListening && !listening) {
      final draft = voice.composerDraft;
      if (draft.isNotEmpty && widget.composer.text != draft) {
        widget.composer.value = TextEditingValue(
          text: draft,
          selection: TextSelection.collapsed(offset: draft.length),
        );
      }
    }
    if (listening && widget.composer.text.isNotEmpty) {
      widget.composer.clear();
    }
    _wasListening = listening;
  }

  @override
  Widget build(BuildContext context) {
    _bind(ref.watch(companionVoiceControllerProvider));
    return widget.child;
  }
}
