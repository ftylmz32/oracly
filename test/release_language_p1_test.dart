/// P1 - Critical release paths stay locale-bound (TR / EN / RU).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/core/copy/reading_flow_copy.dart';
import 'package:oracly_new/core/copy/resilience_copy.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/l10n/app_string_tables.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/modules/oracly_feature_id.dart';
import 'package:oracly_new/core/modules/oracly_feature_l10n.dart';
import 'package:oracly_new/core/modules/oracly_feature_registry.dart';
import 'package:oracly_new/features/companion/data/companion_answer_copy.dart';
import 'package:oracly_new/features/coffee/copy/coffee_copy.dart';
import 'package:oracly_new/features/daily_ritual/services/daily_ritual_reflections.dart';
import 'package:oracly_new/features/palm/copy/palm_copy.dart';
import 'package:oracly_new/features/premium/copy/soul_mate_copy.dart';
import 'package:oracly_new/screens/splash/splash_screen.dart';

void main() {
  const releaseKeys = <String>[
    'splash.tagline',
    'premium.plans_section',
    'premium.plan_name.monthly',
    'reading.flow.breath',
    'tarot.continue.title',
    'tarot.panel.card_message',
    'tarot.history.clear_filter',
    'tarot.history.search_hint',
    'or.answer.tarot',
    'ritual.teaser.quiet',
    'ritual.closing',
    'nav.menu',
    L10nKeys.back,
  ];

  test('release-path keys exist in TR EN RU', () {
    final all = AppStringTables.all;
    for (final key in releaseKeys) {
      expect(all.containsKey(key), isTrue, reason: 'missing key: $key');
      final t = all[key]!;
      expect(t.tr.trim(), isNotEmpty);
      expect(t.en.trim(), isNotEmpty);
      expect(t.ru.trim(), isNotEmpty);
    }
  });

  test('EN release chrome is not Turkish', () {
    OraclyL10n.bind('en');
    expect(SplashScreen.tagline, isNot(contains('Kendini')));
    expect(SplashScreen.tagline, contains('Pause'));
    expect(PremiumCopy.plansSectionTitle, 'MEMBERSHIP PLAN');
    expect(PremiumPlanKind.monthly.periodLabel, isNot('ay'));
    expect(PremiumCopy.planMonthlyLabel, 'Monthly');
    expect(ReadingFlowCopy.introBreath, isNot(contains('nefes')));
    expect(OraclyL10n.t('tarot.continue.title'), 'Continue Reading');
    expect(OraclyL10n.t('tarot.panel.card_message'), isNot(contains('Kart')));
    expect(OraclyL10n.t(L10nKeys.back), 'Back');
    expect(OraclyL10n.t('nav.menu'), 'Menu');
    expect(CoffeeCopy.loveTitle, 'LOVE');
    expect(PalmCopy.leftHand, 'LEFT HAND');
    expect(SoulMateCopy.drawCta, 'CREATE PORTRAIT');
    expect(ResilienceCopy.retryAction, 'TRY AGAIN');
    expect(
      OraclyFeatureRegistry.byId(OraclyFeatureId.coffee)!.labeled,
      'Coffee',
    );
    expect(
      OraclyFeatureRegistry.byId(OraclyFeatureId.palm)!.labeled,
      'Palm',
    );
    expect(CompanionAnswerCopy.tarot, isNot(equals(OraclyL10n.t('or.answer.tarot').isEmpty)));
    expect(CompanionAnswerCopy.tarot, isNot('or.answer.tarot'));
  });

  test('RU release chrome is not Turkish', () {
    OraclyL10n.bind('ru');
    expect(SplashScreen.tagline, isNot(contains('Kendini')));
    expect(PremiumCopy.plansSectionTitle, isNot('UYELIK PLANI'));
    expect(PremiumCopy.plansSectionTitle, isNot('MEMBERSHIP PLAN'));
    expect(PremiumCopy.planMonthlyLabel, isNot('Monthly'));
    expect(PremiumCopy.planMonthlyLabel, isNot('Aylik'));
    expect(OraclyL10n.t('tarot.continue.title'), isNot('Okumaya Devam Et'));
    expect(OraclyL10n.t('tarot.continue.title'), isNot('Continue Reading'));
    expect(OraclyL10n.t(L10nKeys.back), isNot('Geri'));
    expect(OraclyL10n.t(L10nKeys.back), isNot('Back'));
    expect(OraclyL10n.t('nav.menu'), isNot('Menü'));
    expect(OraclyL10n.t('nav.menu'), isNot('Menu'));
    expect(CoffeeCopy.loveTitle, isNot('LOVE'));
    expect(CoffeeCopy.loveTitle, isNot('ASK'));
    expect(SoulMateCopy.screenTitle, isNot('SOULMATE'));
    expect(
      OraclyFeatureRegistry.byId(OraclyFeatureId.coffee)!.labeled,
      isNot('Coffee'),
    );
    expect(
      OraclyFeatureRegistry.byId(OraclyFeatureId.coffee)!.labeled,
      isNot('Kahve'),
    );
    expect(CompanionAnswerCopy.general, isNot('or.answer.general'));
  });

  test('TR release chrome stays natural Turkish', () {
    OraclyL10n.bind('tr');
    expect(SplashScreen.tagline, contains('Kendini'));
    expect(PremiumCopy.plansSectionTitle, contains('PLAN'));
    expect(OraclyL10n.t('tarot.continue.title'), 'Okumaya Devam Et');
    expect(DailyRitualReflections.closing(), isNotEmpty);
    expect(OraclyL10n.t(L10nKeys.back), 'Geri');
  });
}
