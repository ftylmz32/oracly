/// RC-012 — One quiet first screen, then an optional hello.
library;

import 'package:flutter/material.dart';

import '../../features/onboarding/models/onboarding_page_data.dart';
import '../l10n/l10n.dart';

abstract final class OnboardingCopy {
  OnboardingCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get skip => _t('onboard.skip');
  static String get continueLabel => _t('onboard.continue');
  static String get startFirstReading => _t('onboard.start');
  static String get meetLabel => _t('onboard.meet');
  static String get firstReadingHint => _t('onboard.first_hint');
  static String get setupTitle => _t('onboard.setup_title');
  static String get setupSubtitle => _t('onboard.setup_sub');
  static String get nameLabel => _t('onboard.name_label');
  static String get nameHelp => _t('onboard.name_help');
  static String get birthLabel => _t('onboard.birth_label');
  static String get birthHelp => _t('onboard.birth_help');
  static String get birthPick => _t('onboard.birth_pick');
  static String get birthCityHelp => _t('onboard.birth_city_help');
  static String get languageLabel => _t('onboard.language_label');
  static String get languageHelp => _t('onboard.language_help');
  static String get styleLabel => _t('onboard.style_label');
  static String get styleHelp => _t('onboard.style_help');
  static String get title => _t('onboard.p0.title');
  static String get tagline => _t('onboard.p0.sub');
  static String get howItWorks => _t('onboard.p1.sub');
  static String get orHint => _t('onboard.p0.or_hint');
  static String get honesty => _t('onboard.honesty');
  static String get gemsWhisper => _t('onboard.gems_whisper');
  static String get windowsLabel => _t('onboard.windows_label');
  static String get storyWhisper => _t('onboard.story_whisper');

  static List<String> get windows => [
        _t('onboard.window.coffee'),
        _t('onboard.window.palm'),
        _t('onboard.window.sky'),
        _t('onboard.window.star'),
        _t('onboard.window.tarot'),
        _t('onboard.window.or'),
      ];

  static List<OnboardingPageData> get pages => [
        OnboardingPageData(
          title: title,
          subtitle: tagline,
          icon: Icons.auto_awesome_outlined,
        ),
      ];
}
