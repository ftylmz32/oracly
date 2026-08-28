/// Calm first-launch: one screen, then optional profile — never permissions.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/first_session/first_session_intent.dart';
import '../../../../app/providers/app_providers.dart';
import '../../../../core/copy/onboarding_copy.dart';
import '../../../../core/navigation/oracly_page_transitions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/navigation/oracly_navigation.dart';
import '../../../../shared/widgets/oracly_button.dart';
import '../../../../shared/widgets/oracly_text_action.dart';
import '../../../../core/design_system/oracly_cosmic_background.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import '../../../gems/providers/gem_providers.dart';
import '../../../premium/models/personalization_models.dart';
import '../../services/onboarding_profile_saver.dart';
import '../../data/onboarding_setup_draft.dart';
import '../../data/onboarding_setup_draft_store.dart';
import '../widgets/onboarding_page.dart';
import '../widgets/onboarding_setup_form.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _setup = false;
  late final OnboardingSetupDraftStore _draftStore;
  OnboardingSetupDraft? _draft;

  @override
  void initState() {
    super.initState();
    _draftStore = OnboardingSetupDraftStore(ref.read(localStorageProvider));
    _draft = _draftStore.load();
    _setup = _draft != null;
  }

  void _persistDraft(OnboardingSetupDraft next) {
    _draft = next;
    unawaited(_draftStore.save(next));
  }

  Future<void> _complete() async {
    await ref.read(onboardingRepositoryProvider).markCompleted();
    await FirstSessionIntent.requestFirstReading(
      ref.read(localStorageProvider),
    );
    ref.read(firstReadingPendingProvider.notifier).state = true;
    await _draftStore.clear();
    await ref.read(gemStarterGrantProvider).ensureOnce();
    ref.read(gemWalletProvider).reload();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      OraclyPageTransitions.fade(
        page: const OraclyAppShell(initialTab: OraclyTab.home),
      ),
    );
  }

  Future<void> _saveAndComplete({
    required String name,
    DateTime? birthDate,
    String? birthPlace,
    required String language,
    required AiPersonality style,
  }) async {
    await OnboardingProfileSaver.apply(
      ref,
      name: name,
      birthDate: birthDate,
      birthPlace: birthPlace,
      language: language,
      style: style,
    );
    await _complete();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).value;
    final activeLanguage = _draft?.language ?? settings?.language ?? 'tr';
    final activeStyle =
        _draft?.style ?? settings?.aiPersonality ?? AiPersonality.mystical;
    return OraclyScaffold(
      backgroundOverlay: const OraclyCosmicBackground(heroGlow: true),
      child: _setup
          ? OnboardingSetupForm(
              language: activeLanguage,
              style: activeStyle,
              draft: _draft,
              onDraftChanged: _persistDraft,
              onSkip: _complete,
              onContinue: _saveAndComplete,
            )
          : Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: OraclyTextAction(
                    label: OnboardingCopy.skip,
                    onPressed: _complete,
                  ),
                ),
                const Expanded(child: OnboardingPage()),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: OraclyButton(
                    text: OnboardingCopy.meetLabel,
                    isExpanded: true,
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () {
                      final now = DateTime.now().millisecondsSinceEpoch;
                      final initial =
                          _draft ??
                          OnboardingSetupDraft(
                            updatedAtMillis: now,
                            name: null,
                            birthDate: null,
                            birthPlaceTr: null,
                            language: activeLanguage,
                            style: activeStyle,
                          );
                      _persistDraft(initial);
                      setState(() => _setup = true);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
