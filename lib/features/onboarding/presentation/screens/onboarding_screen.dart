/// Calm first-launch: one screen, then optional profile — never permissions.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../core/copy/onboarding_copy.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/navigation/oracly_page_transitions.dart';
import '../../../../core/design_system/oracly_cosmic_background.dart';
import '../../../../shared/navigation/oracly_navigation.dart';
import '../../../../shared/ui/oracly_snackbar.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import '../../../premium/models/personalization_models.dart';
import '../../data/onboarding_setup_draft.dart';
import '../../data/onboarding_setup_draft_store.dart';
import '../../services/onboarding_finish.dart';
import '../../services/onboarding_language.dart';
import '../../services/onboarding_profile_saver.dart';
import '../../encounter/encounter_flow.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.preview = false});

  /// In-memory walkthrough. Does not write profile, gems, or completion.
  final bool preview;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _finishing = false;
  late final OnboardingSetupDraftStore _draftStore;
  OnboardingSetupDraft? _draft;

  @override
  void initState() {
    super.initState();
    _draftStore = OnboardingSetupDraftStore(ref.read(localStorageProvider));
    if (widget.preview) return;
    _draft = _draftStore.load();
    if (_draft != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _resumeDraftLocale());
    }
  }

  Future<void> _resumeDraftLocale() async {
    final d = _draft;
    if (d == null || !mounted) return;
    await OnboardingProfileSaver.apply(
      ref,
      language: d.language,
      style: d.style,
    );
  }

  void _persistDraft(OnboardingSetupDraft next) {
    _draft = next;
    if (widget.preview) return;
    unawaited(_draftStore.save(next));
  }

  Future<void> _finish(OnboardingSetupDraft draft) async {
    if (widget.preview || _finishing) return;
    setState(() => _finishing = true);
    try {
      await finishOnboarding(
        ref: ref,
        draftStore: _draftStore,
        name: draft.name ?? '',
        birthDate: draft.birthDate,
        birthPlace: draft.birthPlaceTr,
        birthTime: draft.birthTime,
        birthTimeKnown: draft.birthTimeKnown,
        interests: draft.interests,
        language: draft.language,
        style: draft.style,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        OraclyPageTransitions.fade(
          page: const OraclyAppShell(initialTab: OraclyTab.home),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _finishing = false);
      OraclySnackBar.show(context, message: OnboardingCopy.completeFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appLocaleProvider);
    final settings = ref.watch(settingsProvider).value;
    final language = OnboardingLanguage.resolve(
      storage: ref.read(localStorageProvider),
      draft: _draft,
      settings: settings,
    );
    OraclyL10n.bind(language);
    final style =
        _draft?.style ?? settings?.aiPersonality ?? AiPersonality.mystical;
    return OraclyScaffold(
      safeArea: false,
      backgroundOverlay: const OraclyCosmicBackground(heroGlow: true),
      child: EncounterFlow(
        draft: _draft ??
            OnboardingSetupDraft(
              updatedAtMillis: DateTime.now().millisecondsSinceEpoch,
              language: language,
              style: style,
            ),
        busy: _finishing,
        onChanged: _persistDraft,
        onFinish: _finish,
      ),
    );
  }
}
