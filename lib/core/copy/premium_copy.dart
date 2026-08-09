/// RC-013 — Premium copy: value without pressure.
library;

abstract final class PremiumCopy {
  PremiumCopy._();

  static const heroTitle = 'OR Premium';
  static const heroSubtitle =
      'İsteğe bağlı bir üyelik alanı — satın alma henüz mağazada yok.';

  static const benefitsSectionTitle = 'Planlanan Premium olanakları';
  static const plannedBenefitLabel = 'Yakında — henüz etkin değil';

  static const ctaExplore = 'Premium\'u incele';
  static const ctaJoin = 'Premium\'a katıl';
  static const ctaActive = 'Premium üyesin';

  static const activatedMessage =
      'Premium açıldı. Kendi ritminle devam edebilirsin.';

  /// Live purchase path is unavailable — shown instead of buy CTAs.
  static const purchaseUnavailableTitle =
      'Premium satın alma yakında kullanılabilir.';
  static const purchaseUnavailableBody =
      'Satın alma şu an mağaza üzerinden yapılamaz.';

  static const planMonthlySubtitle = 'Esnek başlangıç';
  static const planYearlySubtitle = 'Yıllık plan · daha uygun fiyat';
  static const planLifetimeSubtitle = 'Tek seferlik ödeme · kalıcı erişim';
}
