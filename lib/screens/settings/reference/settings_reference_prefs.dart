/// Settings preference groups — live controls or honest unavailable.
library;

import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/navigation/oracly_navigation_service.dart';
import '../../../core/personality/or_personality.dart';
import '../../../core/theme/app_appearance.dart';
import '../../../features/premium/models/personalization_models.dart';
import 'settings_reference_group.dart';
import 'settings_reference_honesty.dart';
import 'settings_reference_notifications.dart';
import 'settings_reference_sound.dart';
import 'settings_reference_tokens.dart';

class SettingsReferencePrefs extends StatelessWidget {
  const SettingsReferencePrefs({
    super.key,
    required this.settings,
    required this.onSave,
    required this.onPickOrStyle,
    required this.onPickLanguage,
    required this.onPickAppearance,
    required this.onPickAtmosphere,
    required this.onPickOutput,
  });

  final PersonalizationSettings settings;
  final Future<void> Function(
    PersonalizationSettings Function(PersonalizationSettings),
  ) onSave;
  final VoidCallback onPickOrStyle;
  final VoidCallback onPickLanguage;
  final VoidCallback onPickAppearance;
  final VoidCallback onPickAtmosphere;
  final VoidCallback onPickOutput;

  String _t(String key) => OraclyL10n.t(
        key,
        languageCode: AppLocale.normalize(settings.language),
      );

  @override
  Widget build(BuildContext context) {
    final lang = AppLocale.normalize(settings.language);
    final themeLabel = switch (settings.appearanceMode) {
      AppAppearanceMode.dark => _t(L10nKeys.themeDark),
      AppAppearanceMode.light => _t(L10nKeys.themeLight),
      AppAppearanceMode.system => _t(L10nKeys.themeSystem),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsReferenceGroup(
          title: _t(L10nKeys.sectionAppearance),
          rows: [
            SettingsReferenceRow(
              icon: Icons.brightness_6_outlined,
              title: _t(L10nKeys.theme),
              subtitle: _t(L10nKeys.themeSubtitle),
              trailingValue: themeLabel,
              onTap: onPickAppearance,
            ),
          ],
        ),
        SizedBox(height: SettingsReferenceTokens.sectionGap),
        SettingsReferenceGroup(
          title: _t(L10nKeys.sectionLanguage),
          rows: [
            SettingsReferenceRow(
              icon: Icons.language_rounded,
              title: _t(L10nKeys.language),
              subtitle: _t(L10nKeys.languageSubtitle),
              trailingValue: AppLocale.displayName(settings.language),
              onTap: onPickLanguage,
            ),
          ],
        ),
        SizedBox(height: SettingsReferenceTokens.sectionGap),
        SettingsReferenceGroup(
          title: _t(L10nKeys.sectionPrivacy),
          rows: [
            SettingsReferenceRow(
              icon: Icons.shield_outlined,
              title: _t(L10nKeys.privacy),
              subtitle: _t(L10nKeys.privacySubtitle),
              showChevron: true,
              onTap: () => OraclyNavigationService.openPrivacy(context),
            ),
          ],
        ),
        SizedBox(height: SettingsReferenceTokens.sectionGap),
        SettingsReferenceGroup(
          title: _t(L10nKeys.sectionOrStyle),
          rows: [
            SettingsReferenceRow(
              icon: Icons.psychology_alt_outlined,
              title: _t(L10nKeys.orStyleTitle),
              subtitle: _t(L10nKeys.orStyleSubtitle),
              trailingValue: OrPersonality.label(
                settings.aiPersonality,
                settings.language,
              ),
              onTap: onPickOrStyle,
            ),
            SettingsReferenceRow(
              icon: Icons.notes_outlined,
              title: _t(L10nKeys.orDepthTitle),
              subtitle: _t(L10nKeys.orDepthSubtitle),
              trailingValue: _t('or.depth.${settings.orResponseDepth.name}'),
              onTap: () => onSave(
                (s) => s.copyWith(orResponseDepth: s.orResponseDepth.next),
              ),
            ),
          ],
        ),
        SizedBox(height: SettingsReferenceTokens.sectionGap),
        SettingsReferenceSound(
          settings: settings,
          onSave: onSave,
          onPickAtmosphere: onPickAtmosphere,
          onPickOutput: onPickOutput,
        ),
        SizedBox(height: SettingsReferenceTokens.sectionGap),
        SettingsReferenceNotifications(
          settings: settings,
          onSave: onSave,
        ),
        SizedBox(height: SettingsReferenceTokens.sectionGap),
        SettingsReferenceHonesty(languageCode: lang),
      ],
    );
  }
}
