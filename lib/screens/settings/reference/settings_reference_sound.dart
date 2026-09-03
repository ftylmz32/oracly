/// Live SFX / music / atmosphere / haptic — output mode lives beside OR voice.
library;

import 'package:flutter/material.dart';

import '../../../core/audio/oracly_feedback_gate.dart';
import '../../../core/l10n/l10n.dart';
import '../../../features/companion/models/or_chat_output_mode.dart';
import '../../../features/premium/models/personalization_models.dart';
import '../../../shared/widgets/oracly_pressable.dart';
import 'settings_or_voice_section.dart';
import 'settings_reference_group.dart';
import 'settings_reference_tokens.dart';

class SettingsReferenceSound extends StatelessWidget {
  const SettingsReferenceSound({
    super.key,
    required this.settings,
    required this.onSave,
    required this.onPickAtmosphere,
    required this.onPickOutput,
  });

  final PersonalizationSettings settings;
  final Future<void> Function(
    PersonalizationSettings Function(PersonalizationSettings),
  )
  onSave;
  final VoidCallback onPickAtmosphere;
  final VoidCallback onPickOutput;

  String _t(String key) =>
      OraclyL10n.t(key, languageCode: AppLocale.normalize(settings.language));

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsReferenceGroup(
          title: _t(L10nKeys.sectionSound),
          rows: [
            SettingsReferenceRow(
              icon: Icons.volume_up_outlined,
              title: _t(L10nKeys.soundTitle),
              subtitle: _t(L10nKeys.soundSubtitle),
              switchValue: settings.soundEnabled,
              onSwitchChanged: (v) async {
                await onSave((s) => s.copyWith(soundEnabled: v));
                if (v) OraclyFeedbackGate.softTap();
              },
            ),
            SettingsReferenceRow(
              icon: Icons.music_note_outlined,
              title: _t(L10nKeys.ambientMusicTitle),
              subtitle: _t(L10nKeys.ambientMusicSubtitle),
              switchValue: settings.ambientMusicEnabled,
              onSwitchChanged: (v) =>
                  onSave((s) => s.copyWith(ambientMusicEnabled: v)),
            ),
            SettingsReferenceRow(
              icon: Icons.auto_awesome_outlined,
              title: _t(L10nKeys.atmosphereTitle),
              subtitle: _t(L10nKeys.atmosphereSubtitle),
              trailingValue: settings.atmosphereSign.labeled(settings.language),
              onTap: onPickAtmosphere,
            ),
            SettingsReferenceRow(
              icon: Icons.vibration_rounded,
              title: _t(L10nKeys.hapticTitle),
              subtitle: _t(L10nKeys.hapticSubtitle),
              switchValue: settings.hapticEnabled,
              onSwitchChanged: (v) async {
                await onSave((s) => s.copyWith(hapticEnabled: v));
                if (v) OraclyTouchFeedback.acknowledge();
              },
            ),
          ],
        ),
        SizedBox(height: SettingsReferenceTokens.sectionGap),
        SettingsReferenceGroup(
          title: _t(L10nKeys.sectionOutput),
          rows: [
            SettingsReferenceRow(
              icon: Icons.record_voice_over_outlined,
              title: _t(L10nKeys.outputTitle),
              subtitle: _t(L10nKeys.outputSubtitle),
              trailingValue: _t(
                OrChatOutputMode.fromStorage(settings.orOutputMode).labelKey,
              ),
              onTap: onPickOutput,
            ),
          ],
        ),
        SizedBox(height: SettingsReferenceTokens.sectionGap),
        SettingsOrVoiceSection(settings: settings, onSave: onSave),
      ],
    );
  }
}
