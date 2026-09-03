/// Settings chooser sheets — live options only.
library;

import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/personality/or_personality.dart';
import '../../../core/theme/app_appearance.dart';
import '../../../features/birth_chart/models/zodiac_sign_id.dart';
import '../../../features/companion/models/or_chat_output_mode.dart';
import '../../../features/premium/models/personalization_models.dart';
import 'settings_choice_sheet.dart';

abstract final class SettingsReferencePickers {
  SettingsReferencePickers._();

  static Future<String?> language(BuildContext context, String current) {
    return showSettingsChoiceSheet<String>(
      context: context,
      title: OraclyL10n.t(L10nKeys.language, languageCode: current),
      current: current,
      options: [for (final o in AppLocale.pickerOptions) (o.$1, o.$2)],
    );
  }

  static Future<AppAppearanceMode?> appearance(
    BuildContext context,
    String lang,
    AppAppearanceMode current,
  ) {
    if (!AppAppearanceModeX.lightModeUserSelectable) {
      return Future<AppAppearanceMode?>.value(null);
    }
    return showSettingsChoiceSheet<AppAppearanceMode>(
      context: context,
      title: OraclyL10n.t(L10nKeys.theme, languageCode: lang),
      current: current,
      options: [
        (
          AppAppearanceMode.dark,
          OraclyL10n.t(L10nKeys.themeDark, languageCode: lang),
        ),
        (
          AppAppearanceMode.light,
          OraclyL10n.t(L10nKeys.themeLight, languageCode: lang),
        ),
        (
          AppAppearanceMode.system,
          OraclyL10n.t(L10nKeys.themeSystem, languageCode: lang),
        ),
      ],
    );
  }

  static Future<ZodiacSignId?> atmosphere(
    BuildContext context,
    String lang,
    ZodiacSignId current,
  ) {
    return showSettingsChoiceSheet<ZodiacSignId>(
      context: context,
      title: OraclyL10n.t(L10nKeys.atmosphereTitle, languageCode: lang),
      current: current,
      options: [
        for (final sign in ZodiacSignId.values) (sign, sign.labeled(lang)),
      ],
    );
  }

  static Future<AiPersonality?> personality(
    BuildContext context,
    String lang,
    AiPersonality current,
  ) {
    return showSettingsChoiceSheet<AiPersonality>(
      context: context,
      title: OraclyL10n.t(L10nKeys.orStyleSheetTitle, languageCode: lang),
      current: current,
      options: [
        (AiPersonality.gentle, OrPersonality.label(AiPersonality.gentle, lang)),
        (
          AiPersonality.mystical,
          OrPersonality.label(AiPersonality.mystical, lang),
        ),
        (AiPersonality.poetic, OrPersonality.label(AiPersonality.poetic, lang)),
        (AiPersonality.direct, OrPersonality.label(AiPersonality.direct, lang)),
      ],
    );
  }

  static Future<OrChatOutputMode?> output(
    BuildContext context,
    String lang,
    OrChatOutputMode current,
  ) {
    return showSettingsChoiceSheet<OrChatOutputMode>(
      context: context,
      title: OraclyL10n.t(L10nKeys.outputTitle, languageCode: lang),
      current: current,
      options: [
        for (final mode in OrChatOutputMode.values)
          (mode, OraclyL10n.t(mode.labelKey, languageCode: lang)),
      ],
    );
  }
}
