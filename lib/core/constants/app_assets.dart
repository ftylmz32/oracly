/// OR-006 — Central registry for premium home screen asset paths.
library;

/// Asset path constants — swap PNG/WebP files without changing widgets.
abstract final class AppAssets {
  AppAssets._();

  static const String _imagesRoot = 'lib/assets/images';
  static const String _iconsRoot = 'lib/assets/icons';

  // ── Home illustrations ───────────────────────────────────────────
  static const String dailyEnergyMoon = '$_imagesRoot/daily_energy_moon.png';
  static const String heroOrbPremium = '$_imagesRoot/hero_orb_premium.png';
  static const String premiumBannerCrown =
      '$_imagesRoot/premium_banner_crown.png';

  // ── Mystic feature icons ─────────────────────────────────────────
  static const String featureTarot = '$_iconsRoot/feature_tarot.png';
  static const String featureDream = '$_iconsRoot/feature_dream.png';
  static const String featureAstrology = '$_iconsRoot/feature_astrology.png';
  static const String featureStarMap = '$_iconsRoot/feature_star_map.png';
  static const String featureAiCrystal = '$_iconsRoot/feature_ai_crystal.png';
}
