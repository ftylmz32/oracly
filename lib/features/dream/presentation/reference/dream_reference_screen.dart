/// Reference-accurate Dream Analysis screen — rebuilt from design reference.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/providers/backend_providers.dart'
    show localDataOwnerEpochProvider;
import '../../../../shared/ui/oracly_snackbar.dart';
import '../../../../shared/ui/oracly_permission_dialog.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import '../../controllers/dream_analysis_controller.dart';
import '../../copy/dream_copy.dart';
import '../../models/dream_emotion.dart';
import '../../models/dream_entry_context.dart';
import '../../models/dream_entry_selection.dart';
import '../../providers/dream_providers.dart';
import '../../services/dream_owner_guard.dart';
import '../../services/dream_paid_submit.dart';
import '../../../quality_loop/providers/quality_loop_providers.dart';
import '../../../quality_loop/widgets/quality_loop_gate.dart';
import '../../../../core/quality/quality_feature.dart';
import '../../voice/dream_voice_draft.dart';
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
  bool _composing = false;
  DreamAnalysisController? _analysis;
  int _clearGeneration = DreamOwnerGuard.clearGeneration;

  @override
  void dispose() {
    final analysis = _analysis;
    if (analysis != null) scheduleMicrotask(analysis.releaseSession);
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
      entry: DreamEntrySelection.of(
        chips: _selectedChips,
        guided: _guidedAnswers,
      ),
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
    unawaited(DreamPaidSubmit.clearAttempt(ref));
    controller.reset();
    _narrativeController.clear();
    setState(() {
      _composing = false;
      _selectedChips.clear();
      _guidedAnswers.clear();
    });
  }

  void _editDream(DreamAnalysisController controller) {
    final dream = controller.dream;
    if (dream == null) return;
    final entry = dream.entry;
    _narrativeController.text = dream.narrative;
    unawaited(DreamPaidSubmit.clearAttempt(ref));
    controller.reset();
    setState(() {
      _composing = true;
      if (entry == null) {
        _selectedChips.clear();
        _guidedAnswers.clear();
      } else {
        entry.applyTo(chips: _selectedChips, guided: _guidedAnswers);
      }
    });
  }

  /// A mounted screen must not carry the prior owner's typed narrative, nor
  /// a narrative whose Dream data was just cleared.
  void _clearForOwnerChange() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(dreamVoiceControllerProvider).reset();
      _narrativeController.clear();
      setState(() {
        _composing = false;
        _selectedChips.clear();
        _guidedAnswers.clear();
      });
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
    _analysis = analysis;
    if (_clearGeneration != DreamOwnerGuard.clearGeneration) {
      _clearGeneration = DreamOwnerGuard.clearGeneration;
      _clearForOwnerChange();
    }
    final voice = ref.watch(dreamVoiceControllerProvider);
    ref.listen(localDataOwnerEpochProvider, (_, _) => _clearForOwnerChange());
    ref.listen(dreamVoiceControllerProvider, (previous, next) {
      DreamVoiceDraft.onPhase(
        narrative: _narrativeController,
        from: previous?.phase,
        next: next,
      );
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
            composing: _composing,
            onChipToggle: _toggleChip,
            onGuidedChanged: _onGuidedChanged,
            onVoiceTap: _onVoiceTap,
            onCompose: () => setState(() => _composing = true),
            onSubmit: () => _submit(analysis),
            onEditDream: () => _editDream(analysis),
            onStopVoice: voice.stop,
            onListenAgain: () => DreamVoiceDraft.listenAgain(
              askMicrophone: () => OraclyPermissionDialog.microphone(context),
              voice: voice,
            ),
            onAnalyzeVoice: () => _submit(analysis),
            onVoiceRetry: _retryVoice,
            onVoiceBack: () => DreamVoiceDraft.abandon(
              narrative: _narrativeController,
              voice: voice,
            ),
            onNewDream: () => _reset(analysis),
            onAnalysisRetry: () {
              if (analysis.reinterpretFailed) {
                unawaited(analysis.reinterpret().catchError((Object _) {}));
                return;
              }
              setState(() => _composing = true);
              _submit(analysis);
            },
            onAnalysisBack: () {
              if (analysis.reinterpretFailed) return analysis.returnToReading();
              analysis.reset();
              setState(() => _composing = false);
            },
            onOpenSaved: analysis.openSaved,
          ),
        ),
      ),
    );
  }
}
