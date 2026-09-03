/// Dream screen body — analysis phases plus Sesli Anlat session.
library;

import 'package:flutter/material.dart';

import '../../controllers/dream_analysis_controller.dart';
import '../../controllers/dream_voice_controller.dart';
import '../../copy/dream_copy.dart';
import '../../models/dream_entry_context.dart';
import '../../voice/dream_voice_phase.dart';
import 'dream_reference_entry_view.dart';
import 'dream_reference_error_view.dart';
import 'dream_reference_loading_view.dart';
import 'dream_reference_recording_view.dart';
import 'dream_reference_result_view.dart';
import 'dream_reference_voice_review_view.dart';

class DreamReferenceSessionBody extends StatelessWidget {
  const DreamReferenceSessionBody({
    super.key,
    required this.analysis,
    required this.voice,
    required this.narrative,
    required this.selectedChips,
    required this.guidedAnswers,
    required this.onChipToggle,
    required this.onGuidedChanged,
    required this.onVoiceTap,
    required this.onSubmit,
    required this.onEditDream,
    required this.onStopVoice,
    required this.onListenAgain,
    required this.onAnalyzeVoice,
    required this.onVoiceRetry,
    required this.onVoiceBack,
    required this.onNewDream,
    required this.onAnalysisRetry,
    required this.onAnalysisBack,
  });

  final DreamAnalysisController analysis;
  final DreamVoiceController voice;
  final TextEditingController narrative;
  final Set<DreamEntryChipId> selectedChips;
  final Map<DreamGuidedQuestionId, String> guidedAnswers;
  final ValueChanged<DreamEntryChipId> onChipToggle;
  final void Function(DreamGuidedQuestionId id, String value) onGuidedChanged;
  final VoidCallback onVoiceTap;
  final VoidCallback onSubmit;
  final VoidCallback onEditDream;
  final VoidCallback onStopVoice;
  final VoidCallback onListenAgain;
  final VoidCallback onAnalyzeVoice;
  final VoidCallback onVoiceRetry;
  final VoidCallback onVoiceBack;
  final VoidCallback onNewDream;
  final VoidCallback onAnalysisRetry;
  final VoidCallback onAnalysisBack;

  @override
  Widget build(BuildContext context) {
    return switch (analysis.phase) {
      DreamJourneyPhase.organizing ||
      DreamJourneyPhase.reflecting =>
        DreamReferenceLoadingView(
          key: ValueKey(analysis.phase.name),
          message: DreamCopy.organizing,
        ),
      DreamJourneyPhase.complete => DreamReferenceResultView(
          key: const ValueKey('complete'),
          controller: analysis,
          onNewDream: onNewDream,
          onEditDream: onEditDream,
        ),
      DreamJourneyPhase.error => DreamReferenceErrorView(
          key: const ValueKey('analysis-error'),
          message: analysis.errorMessage ?? DreamCopy.analysisFailed,
          onRetry: onAnalysisRetry,
          onBack: onAnalysisBack,
        ),
      DreamJourneyPhase.entry => _voiceOrEntry(),
    };
  }

  Widget _voiceOrEntry() {
    return switch (voice.phase) {
      DreamVoicePhase.recording ||
      DreamVoicePhase.processing =>
        DreamReferenceRecordingView(
          key: const ValueKey('voice-recording'),
          phase: voice.phase,
          liveText: voice.transcript,
          onStop: onStopVoice,
          onCancel: onVoiceBack,
        ),
      DreamVoicePhase.transcribed => DreamReferenceVoiceReviewView(
          key: const ValueKey('voice-review'),
          controller: narrative,
          onListenAgain: onListenAgain,
          onAnalyze: onAnalyzeVoice,
          onCancel: onVoiceBack,
        ),
      DreamVoicePhase.error => DreamReferenceErrorView(
          key: const ValueKey('voice-error'),
          message: voice.errorMessage ?? DreamCopy.voiceSpeechError,
          onRetry: onVoiceRetry,
          onBack: onVoiceBack,
        ),
      DreamVoicePhase.idle => DreamReferenceEntryView(
          key: const ValueKey('entry'),
          controller: narrative,
          selectedChips: selectedChips,
          guidedAnswers: guidedAnswers,
          onChipToggle: onChipToggle,
          onGuidedChanged: onGuidedChanged,
          onVoiceTap: onVoiceTap,
          onSubmit: onSubmit,
        ),
    };
  }
}
