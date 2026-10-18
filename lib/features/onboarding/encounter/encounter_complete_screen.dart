/// Finish the introduction from Home — only the missing scenes, nothing reset.
///
/// Reuses the encounter's name and sky scenes. Never marks onboarding,
/// grants gems, requests a first reading or touches an existing birth chart.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/copy/onboarding_copy.dart';
import '../../../core/design_system/oracly_cosmic_background.dart';
import '../../../core/l10n/l10n.dart';
import '../../../shared/ui/oracly_snackbar.dart';
import '../../../shared/widgets/oracly_scaffold.dart';
import '../../premium/models/personalization_models.dart';
import '../data/onboarding_setup_draft.dart';
import '../services/onboarding_profile_saver.dart';
import 'encounter_name_scene.dart';
import 'encounter_sky_scene.dart';

class EncounterCompleteScreen extends ConsumerStatefulWidget {
  const EncounterCompleteScreen({
    super.key,
    required this.askName,
    required this.askBirth,
    this.preview = false,
  }) : assert(askName || askBirth);

  final bool askName;
  final bool askBirth;

  /// Debug preview: walks the scenes, writes nothing.
  final bool preview;

  @override
  ConsumerState<EncounterCompleteScreen> createState() =>
      _EncounterCompleteScreenState();
}

class _EncounterCompleteScreenState
    extends ConsumerState<EncounterCompleteScreen> {
  final _pages = PageController();
  final _name = TextEditingController();
  late OnboardingSetupDraft _draft = OnboardingSetupDraft(
    updatedAtMillis: DateTime.now().millisecondsSinceEpoch,
    language: OraclyL10n.code,
    style: AiPersonality.mystical,
  );
  bool _busy = false;

  @override
  void dispose() {
    _pages.dispose();
    _name.dispose();
    super.dispose();
  }

  void _leave([bool saved = false]) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(saved);
  }

  void _toSky() {
    FocusManager.instance.primaryFocus?.unfocus();
    _pages.animateToPage(
      1,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeInOutCubic,
    );
  }

  void _toName() {
    _pages.animateToPage(
      0,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeInOutCubic,
    );
  }

  /// Saves only what was entered here; empty answers leave stores untouched.
  Future<void> _save() async {
    if (_busy) return;
    final name = widget.askName ? _name.text.trim() : '';
    final date = widget.askBirth ? _draft.birthDate : null;
    if (widget.preview || (name.isEmpty && date == null)) {
      _leave();
      return;
    }
    setState(() => _busy = true);
    try {
      await OnboardingProfileSaver.apply(
        ref,
        name: name,
        birthDate: date,
        birthPlace: _draft.birthPlaceTr,
        birthTime: _draft.birthTime,
        birthTimeKnown: _draft.birthTimeKnown,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      OraclySnackBar.show(context, message: OnboardingCopy.completeFailed);
      return;
    }
    if (mounted) _leave(true);
  }

  @override
  Widget build(BuildContext context) {
    final both = widget.askName && widget.askBirth;
    return OraclyScaffold(
      safeArea: false,
      backgroundOverlay: const OraclyCosmicBackground(heroGlow: true),
      child: PageView(
        controller: _pages,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          if (widget.askName)
            EncounterNameScene(
              controller: _name,
              busy: _busy,
              showProgress: false,
              onContinue: both ? _toSky : _save,
              onSkip: _save,
              onBack: _leave,
            ),
          if (widget.askBirth)
            EncounterSkyScene(
              draft: _draft,
              busy: _busy,
              showProgress: false,
              onChanged: (next) => setState(() => _draft = next),
              onContinue: _save,
              onSkip: _save,
              onBack: both ? _toName : _leave,
            ),
        ],
      ),
    );
  }
}
