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
import '../widgets/onboarding_screen_body.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _setup = false;
  bool _finishing = false;
  late final OnboardingSetupDraftStore _draftStore;
  OnboardingSetupDraft? _draft;

  @override
  void initState() {
    super.initState();
    _draftStore = OnboardingSetupDraftStore(ref.read(localStorageProvider));
    _draft = _draftStore.load();
    _setup = _draft != null;
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
    final languageChanged = _draft?.language != next.language;
    _draft = next;
    unawaited(_draftStore.save(next));
    if (languageChanged && mounted) setState(() {});
  }

  Future<void> _finish({
    String name = '',
    DateTime? birthDate,
    String? birthPlace,
    required String language,
    required AiPersonality style,
  }) async {
    if (_finishing) return;
    setState(() => _finishing = true);
    try {
      await finishOnboarding(
        ref: ref,
        draftStore: _draftStore,
        name: name,
        birthDate: birthDate,
        birthPlace: birthPlace,
        language: language,
        style: style,
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

  void _openSetup(String language, AiPersonality style) {
    if (_finishing) return;
    _persistDraft(
      _draft ??
          OnboardingSetupDraft(
            updatedAtMillis: DateTime.now().millisecondsSinceEpoch,
            language: language,
            style: style,
          ),
    );
    setState(() => _setup = true);
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
      backgroundOverlay: const OraclyCosmicBackground(heroGlow: true),
      child: OnboardingScreenBody(
        setup: _setup,
        busy: _finishing,
        language: language,
        style: style,
        draft: _draft,
        onDraftChanged: _persistDraft,
        onLanguageLive: (code) async {
          OraclyL10n.bind(code);
          await OnboardingProfileSaver.apply(ref, language: code);
          if (mounted) setState(() {});
        },
        onSkipSetup: ({required language, required style}) =>
            _finish(language: language, style: style),
        onContinue: _finish,
        onSkipIntro: () => unawaited(_finish(language: language, style: style)),
        onMeet: () => _openSetup(language, style),
      ),
    );
  }
}
