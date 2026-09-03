/// Reference-accurate Dream Analysis screen — rebuilt from design reference.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../shared/ui/oracly_snackbar.dart';
import '../../../../shared/ui/oracly_permission_dialog.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import '../../controllers/dream_analysis_controller.dart';
import '../../copy/dream_copy.dart';
import '../../models/dream_emotion.dart';
import '../../models/dream_entry_context.dart';
import '../../providers/dream_providers.dart';
import '../../services/dream_paid_submit.dart';
import '../../../quality_loop/providers/quality_loop_providers.dart';
import '../../../quality_loop/widgets/quality_loop_gate.dart';
import '../../../../core/quality/quality_feature.dart';
import '../../voice/dream_voice_phase.dart';
import 'dream_reference_atmosphere.dart';
import 'dream_reference_session_body.dart';

class DreamReferenceScreen extends ConsumerStatefulWidget {
  const DreamReferenceScreen({super.key});

  @override
  ConsumerState<DreamReferenceScreen> createState() =>
      _DreamReferenceScreenState();
}

class _DreamReferenceScreenState extends ConsumerState<DreamReferenceScreen> {
  final _narrativeController = TextEditingController();
  final _selectedChips = <DreamEntryChipId>{};
  final _guidedAnswers = <DreamGuidedQuestionId, String>{};

  @override
  void dispose() {
    _narrativeController.dispose();
    super.dispose();
  }

  List<String> _buildTags() {
    return DreamEntryContext.tagsFor(
      chips: _selectedChips,
      guided: _guidedAnswers,
    );
  }

  List<DreamEmotion> _buildEmotions() {
    return DreamEntryContext.emotionsFor(_selectedChips);
  }

  Future<void> _submit(DreamAnalysisController controller) async {
    final text = _narrativeController.text.trim();
    if (text.length < 12) {
      OraclySnackBar.show(context, message: DreamCopy.narrativeTooShort);
      return;
    }
    if (controller.phase == DreamJourneyPhase.organizing ||
        controller.phase == DreamJourneyPhase.reflecting) {
      return;
    }
    ref.read(dreamVoiceControllerProvider).reset();
    await DreamPaidSubmit.run(
      ref: ref,
      context: context,
      controller: controller,
      narrative: text,
      emotions: _buildEmotions(),
      tags: _buildTags(),
    );
  }

  Future<void> _onVoiceTap() async {
    final allowed = await OraclyPermissionDialog.microphone(context);
    if (allowed != true || !mounted) return;
    await ref.read(dreamVoiceControllerProvider).start();
  }

  Future<void> _retryVoice() async {
    final voice = ref.read(dreamVoiceControllerProvider);
    if (voice.errorMessage == DreamCopy.voicePermissionPermanent) {
      await openAppSettings();
    }
    if (!mounted) return;
    final allowed = await OraclyPermissionDialog.microphone(context);
    if (allowed != true || !context.mounted) return;
    await voice.start();
  }

  void _reset(DreamAnalysisController controller) {
    ref.read(qualitySignalRecorderProvider).abandonedIfOpen(
          QualityFeature.dream,
        );
    ref.read(dreamVoiceControllerProvider).reset();
    controller.reset();
    _narrativeController.clear();
    setState(() {
      _selectedChips.clear();
      _guidedAnswers.clear();
    });
  }

  void _editDream(DreamAnalysisController controller) {
    final dream = controller.dream;
    if (dream == null) return;
    _narrativeController.text = dream.narrative;
    controller.reset();
    setState(() {
      _selectedChips.clear();
      _guidedAnswers.clear();
    });
  }

  void _toggleChip(DreamEntryChipId chip) {
    setState(() {
      if (_selectedChips.contains(chip)) {
        _selectedChips.remove(chip);
      } else {
        _selectedChips.add(chip);
      }
    });
  }

  void _onGuidedChanged(DreamGuidedQuestionId id, String value) {
    setState(() => _guidedAnswers[id] = value);
  }

  @override
  Widget build(BuildContext context) {
    final analysis = ref.watch(dreamAnalysisControllerProvider);
    final voice = ref.watch(dreamVoiceControllerProvider);
    ref.listen(dreamVoiceControllerProvider, (previous, next) {
      if (next.phase == DreamVoicePhase.transcribed &&
          _narrativeController.text != next.transcript) {
        _narrativeController.text = next.transcript;
      }
    });

    return QualityLoopGate(
      feature: QualityFeature.dream,
      child: OraclyScaffold(
        backgroundOverlay: const DreamReferenceAtmosphere(
          child: SizedBox.shrink(),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 420),
          child: DreamReferenceSessionBody(
            analysis: analysis,
            voice: voice,
            narrative: _narrativeController,
            selectedChips: _selectedChips,
            guidedAnswers: _guidedAnswers,
            onChipToggle: _toggleChip,
            onGuidedChanged: _onGuidedChanged,
            onVoiceTap: _onVoiceTap,
            onSubmit: () => _submit(analysis),
            onEditDream: () => _editDream(analysis),
            onStopVoice: voice.stop,
            onListenAgain: () {
              _narrativeController.clear();
              OraclyPermissionDialog.microphone(context).then((allowed) {
                if (allowed == true) voice.listenAgain();
              });
            },
            onAnalyzeVoice: () => _submit(analysis),
            onVoiceRetry: _retryVoice,
            onVoiceBack: voice.reset,
            onNewDream: () => _reset(analysis),
            onAnalysisRetry: () => _submit(analysis),
            onAnalysisBack: analysis.reset,
          ),
        ),
      ),
    );
  }
}
