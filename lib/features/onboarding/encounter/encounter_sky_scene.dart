/// Birth facts, one quiet focus. Unknown time stays unknown.
library;

import 'package:flutter/material.dart';

import '../../../core/copy/onboarding_copy.dart';
import '../../../core/l10n/oracly_format.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../birth_chart/copy/birth_chart_copy.dart';
import '../../birth_chart/data/birth_chart_cities.dart';
import '../../birth_chart/presentation/widgets/birth_chart_city_picker.dart';
import '../data/onboarding_setup_draft.dart';
import 'encounter_birth_wheel.dart';
import 'encounter_chrome.dart';
import 'encounter_sky_hero.dart';
import 'encounter_sky_rows.dart';

class EncounterSkyScene extends StatelessWidget {
  const EncounterSkyScene({
    super.key,
    required this.draft,
    required this.onChanged,
    required this.onContinue,
    required this.onSkip,
    required this.onBack,
    this.busy = false,
    this.showProgress = true,
  });

  final OnboardingSetupDraft draft;
  final ValueChanged<OnboardingSetupDraft> onChanged;
  final VoidCallback onContinue;
  final VoidCallback onSkip;
  final VoidCallback onBack;
  final bool busy;

  /// Five-scene dots; off when the sky is reached from Home.
  final bool showProgress;

  Future<void> _date(BuildContext context) async {
    final picked = await showEncounterBirthWheel(
      context,
      initial: draft.birthDate,
    );
    if (picked == null) return;
    onChanged(draft.copy(birthDate: picked, setBirthDate: true));
  }

  Future<void> _time(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: draft.birthHour ?? 12,
        minute: draft.birthMinute ?? 0,
      ),
    );
    if (picked == null) return;
    onChanged(
      draft.copy(
        birthTimeKnown: true,
        birthHour: picked.hour,
        birthMinute: picked.minute,
        setTime: true,
      ),
    );
  }

  Future<void> _city(BuildContext context) async {
    final picked = await showBirthChartCityPicker(
      context,
      selected: BirthChartCities.byName(draft.birthPlaceTr),
    );
    if (picked == null) return;
    onChanged(draft.copy(birthPlaceTr: picked.nameTr, setPlace: true));
  }

  void _unknown() {
    onChanged(
      draft.copy(
        birthTimeKnown: false,
        birthHour: null,
        birthMinute: null,
        setTime: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hero = MediaQuery.sizeOf(context).height * 0.34;
    return Column(
      children: [
        EncounterSkyHero(height: hero.clamp(168, 300)),
        Expanded(
          child: SingleChildScrollView(
            child: EncounterChrome(
              scene: 3,
              title: OnboardingCopy.skyTitle,
              subtitle: OnboardingCopy.skyHelp,
              action: OnboardingCopy.continueLabel,
              onAction: onContinue,
              onSkip: onSkip,
              onBack: onBack,
              busy: busy,
              showProgress: showProgress,
              extra: Column(
                children: [
                  EncounterSkyRow(
                    label: OnboardingCopy.birthLabel,
                    value: draft.birthDate == null
                        ? OnboardingCopy.birthPick
                        : OraclyFormat.date(draft.birthDate!),
                    onTap: () => _date(context),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    OnboardingCopy.skyTime,
                    style: AppTextStyles.labelMedium,
                  ),
                  const SizedBox(height: 6),
                  EncounterTimeChoice(
                    known: draft.birthTimeKnown,
                    onKnow: () => _time(context),
                    onUnknown: _unknown,
                  ),
                  if (draft.birthTimeKnown && draft.birthTime != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        OraclyFormat.time(draft.birthTime!),
                        style: AppTextStyles.labelMedium,
                      ),
                    ),
                  const SizedBox(height: 8),
                  EncounterSkyRow(
                    label: OnboardingCopy.skyCity,
                    value: draft.birthPlaceTr ?? BirthChartCopy.birthPlaceHint,
                    onTap: () => _city(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
