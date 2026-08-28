/// RC-013 — Premium copy: value without pressure.
library;

import '../domain/models/premium_plan.dart';
import '../l10n/l10n.dart';

abstract final class PremiumCopy {
  PremiumCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get heroTitle => _t('premium.hero_title');
  static String get heroLead => _t('premium.hero_lead');
  static String get heroSubtitle => _t('premium.hero_subtitle');
  static String get benefitsSectionTitle => _t('premium.benefits_title');
  static String get experiencesSectionTitle => _t('premium.experiences_title');
  static String get includedSectionTitle => _t('premium.included_title');
  static String get exclusiveLabel => _t('premium.exclusive');
  static String gemNote(int amount) =>
      _t('premium.gem_note').replaceAll('{n}', '$amount');
  static String get gemSectionTitle => _t('premium.gem_section_title');
  static String get benefitSoulmateTitle => _t('premium.benefit.soulmate.title');
  static String get benefitSoulmateBody => _t('premium.benefit.soulmate.body');
  static String get benefitCoffeeTitle => _t('premium.benefit.coffee.title');
  static String get benefitCoffeeBody => _t('premium.benefit.coffee.body');
  static String get benefitPalmTitle => _t('premium.benefit.palm.title');
  static String get benefitPalmBody => _t('premium.benefit.palm.body');
  static String get benefitDiscoveryTitle =>
      _t('premium.benefit.discovery.title');
  static String get benefitDiscoveryBody => _t('premium.benefit.discovery.body');
  static String get benefitOrTitle => _t('premium.benefit.or.title');
  static String get benefitOrBody => _t('premium.benefit.or.body');
  static String get benefitJourneyTitle => _t('premium.benefit.journey.title');
  static String get benefitJourneyBody => _t('premium.benefit.journey.body');
  static String get benefitAtmosphereTitle =>
      _t('premium.benefit.atmosphere.title');
  static String get benefitAtmosphereBody =>
      _t('premium.benefit.atmosphere.body');
  static String get benefitDepthTitle => _t('premium.benefit.depth.title');
  static String get benefitDepthBody => _t('premium.benefit.depth.body');
  static String get benefitContinuityTitle =>
      _t('premium.benefit.continuity.title');
  static String get benefitContinuityBody =>
      _t('premium.benefit.continuity.body');
  static String get benefitPersonalizationTitle =>
      _t('premium.benefit.personalization.title');
  static String get benefitPersonalizationBody =>
      _t('premium.benefit.personalization.body');
  static String get whatTitle => _t('premium.what_title');
  static String get whatBody => _t('premium.what_body');
  static String get whyTitle => _t('premium.why_title');
  static String get whyBody => _t('premium.why_body');
  static String get activeBody => _t('premium.active_body');
  static String get unlockTitle => whatTitle;
  static String get gateTitle => _t('premium.gate_title');
  static String get gateLead => _t('premium.gate_lead');
  static List<String> get unlocks => [
        benefitDepthTitle,
        benefitContinuityTitle,
        benefitPersonalizationTitle,
      ];
  static String get entitlementUnverified =>
      _t('premium.entitlement_unverified');
  static String get ctaExplore => _t('premium.cta_explore');
  static String get homeBannerTitle => _t('premium.home_banner_title');
  static String get homeBannerBody => _t('premium.home_banner_body');
  static String get ctaJoin => _t('premium.cta_join');
  static String get ctaActive => _t('premium.cta_active');
  static String get ctaUnavailable => _t('premium.cta_unavailable');
  static String get ctaHint => _t('premium.cta_hint');
  static String get ctaRetryStore => _t('premium.cta_retry_store');
  static String get ctaHintConfigured => _t('premium.cta_hint_configured');
  static String get loadingBody => _t('premium.loading_body');
  static String get errorRetry => _t('premium.error_retry');
  static String get planPricePending => _t('premium.plan_price_pending');
  static String get ctaRestore => _t('premium.cta_restore');
  static String get ctaBusy => _t('premium.cta_busy');
  static String get activatedMessage => _t('premium.activated');
  static String get purchaseUnavailable => ctaUnavailable;
  static String get purchaseFailed => _t('premium.purchase_failed');
  static String get purchaseCancelled => _t('premium.purchase_cancelled');
  static String get purchasePending => _t('premium.purchase_pending');
  static String get restoreUnavailable => _t('premium.restore_unavailable');
  static String get restoreFailed => _t('premium.restore_failed');
  static String get restoreNone => _t('premium.restore_none');
  static String get restoreSuccess => _t('premium.restore_success');
  static String get accessRequired => _t('premium.access_required');
  static String get planMonthlySubtitle => _t('premium.plan_monthly');
  static String get planYearlySubtitle => _t('premium.plan_yearly');
  static String get planLifetimeSubtitle => _t('premium.plan_lifetime');
  static String get plansSectionTitle => _t('premium.plans_section');
  static String get planMonthlyLabel => _t('premium.plan_name.monthly');
  static String get planYearlyLabel => _t('premium.plan_name.yearly');
  static String get planLifetimeLabel => _t('premium.plan_name.lifetime');
  static String get planPeriodMonthly => _t('premium.plan_period.monthly');
  static String get planPeriodYearly => _t('premium.plan_period.yearly');
  static String get planPeriodLifetime => _t('premium.plan_period.lifetime');

  static String planLabel(PremiumPlanKind kind) => switch (kind) {
        PremiumPlanKind.monthly => planMonthlyLabel,
        PremiumPlanKind.yearly => planYearlyLabel,
        PremiumPlanKind.lifetime => planLifetimeLabel,
      };

  static String planPeriod(PremiumPlanKind kind) => switch (kind) {
        PremiumPlanKind.monthly => planPeriodMonthly,
        PremiumPlanKind.yearly => planPeriodYearly,
        PremiumPlanKind.lifetime => planPeriodLifetime,
      };
}
