/// Freemium V1 copy (see `table_freemium.dart`).
library;

import '../../../core/l10n/l10n.dart';
import '../models/reading_allowance.dart';

abstract final class FreemiumCopy {
  FreemiumCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String freeTitle(ReadingAllowanceKind kind) => _t(
    kind == ReadingAllowanceKind.coffee
        ? 'freemium.coffee.free_title'
        : 'freemium.palm.free_title',
  );

  static String premiumTitle(ReadingAllowanceKind kind) => _t(
    kind == ReadingAllowanceKind.coffee
        ? 'freemium.coffee.premium_title'
        : 'freemium.palm.premium_title',
  );

  static String usedTitle(ReadingAllowanceKind kind, {required bool premium}) {
    final coffee = kind == ReadingAllowanceKind.coffee;
    if (premium) {
      return _t(
        coffee
            ? 'freemium.coffee.used_premium_title'
            : 'freemium.palm.used_premium_title',
      );
    }
    return _t(coffee ? 'freemium.coffee.used_title' : 'freemium.palm.used_title');
  }

  static String get coffeeCta => _t('freemium.coffee.cta');
  static String get freeNote => _t('freemium.free_note');
  static String get premiumBadge => _t('freemium.premium_badge');
  static String get usedBody => _t('freemium.used_body');
  static String get usedPremiumOffer => _t('freemium.used_premium_offer');
  static String get checking => _t('freemium.checking');
  static String get checkFailed => _t('freemium.check_failed');
  static String get retry => _t('freemium.retry');
  static String get recheck => _t('freemium.recheck');
  static String get seePremium => _t('freemium.see_premium');
  static String get backHome => _t('freemium.back_home');

  static String get premiumHeroLead => _t('freemium.premium.hero_lead');
  static String get premiumSectionTitle => _t('freemium.premium.section_title');
  static String get premiumCoffeeTitle => _t('freemium.premium.coffee_title');
  static String get premiumPalmTitle => _t('freemium.premium.palm_title');
  static String get premiumDailyFreeBody =>
      _t('freemium.premium.daily_free_body');
  static String get premiumInstantTitle => _t('freemium.premium.instant_title');
  static String get premiumInstantBody => _t('freemium.premium.instant_body');
  static String get premiumCupMapTitle => _t('freemium.premium.cup_map_title');
  static String get premiumCupMapBody => _t('freemium.premium.cup_map_body');
  static String get premiumSameCare => _t('freemium.premium.same_care');
  static String get premiumActiveNote => _t('freemium.premium.active_note');

  static String get cupMapLockedBody => _t('freemium.cup_map.locked_body');
  static String get cupMapLockedCta => _t('freemium.cup_map.locked_cta');
  static String get cupMapDelete => _t('freemium.cup_map.delete');
  static String get cupMapDeleteTitle => _t('freemium.cup_map.delete_title');
  static String get cupMapDeleteBody => _t('freemium.cup_map.delete_body');
  static String get cupMapDeleteConfirm =>
      _t('freemium.cup_map.delete_confirm');
  static String get cupMapDeleteCancel => _t('freemium.cup_map.delete_cancel');
  static String get cupMapChecking => _t('freemium.cup_map.checking');
  static String get cupMapCheckFailed => _t('freemium.cup_map.check_failed');
  static String get cupMapReviewNote => _t('freemium.cup_map.review_note');
}
