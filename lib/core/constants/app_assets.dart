/// OR-006 — Central registry for premium home screen asset paths.
library;

/// Asset path constants — swap PNG/WebP files without changing widgets.
abstract final class AppAssets {
  AppAssets._();

  static const String _imagesRoot = 'lib/assets/images';
  static const String _homeRoot = '$_imagesRoot/home';
  static const String _iconsRoot = 'lib/assets/icons';
  static const String _brandRoot = 'lib/assets/brand';

  /// Official ORACLY logo — crescent · oracle profile · star (do not redraw).
  /// Never use legacy circular orbit/vesica marks as brand identity.
  static const String brandLogo = '$_brandRoot/oracly_logo.png';

  /// Splash-only master — black keyed out for cosmic background integration.
  static const String brandLogoSplash = '$_brandRoot/oracly_logo_splash.png';

  /// Final single-image Flutter splash (crescent/woman + ORACLY wordmark).
  static const String splashFinal = 'assets/splash/oracly_splash_final.png';

  // ── Major cinema plates (photoreal only; Flutter owns all text) ──
  /// Runtime moon — WebP. PNG master: design/daily_energy/ (not bundled).
  static const String dailyEnergyMoon =
      '$_imagesRoot/daily_moon_photoreal.webp';
  static const String dailyMoonPhotoreal =
      '$_imagesRoot/daily_moon_photoreal.webp';
  static const String heroOrbPremium = '$_imagesRoot/or_presence_orb.webp';
  static const String premiumBannerCrown =
      '$_premiumRoot/premium_crown_photoreal.webp';
  static const String coffeeRitualHero = '$_imagesRoot/coffee_ritual_hero.webp';
  static const String tarotHero = '$_imagesRoot/tarot_hero.webp';
  static const String homeHeroMoon = '$_homeRoot/home_hero_moon.webp';
  static const String homeOrGuide = '$_homeRoot/home_or_guide.webp';

  /// Luna chat hero — extracted from owned design reference (portrait only).
  static const String lunaPortraitHero =
      '$_imagesRoot/companion/luna_portrait_hero_v2_runtime.png';

  /// Circular Luna avatar for assistant bubbles.
  static const String lunaAvatar =
      '$_imagesRoot/companion/luna_portrait_hero_v2_runtime.png';

  /// Soft nebula wash behind Luna hero (owned reference, blurred).
  static const String lunaNebulaWash =
      '$_imagesRoot/companion/luna_nebula_wash.webp';
  static const String homeTarot = '$_homeRoot/home_tarot.webp';
  static const String homeDream = '$_homeRoot/home_dream.webp';
  static const String dreamEntryHero =
      '$_imagesRoot/dream/dream_entry_hero.webp';
  static const String homeAstrology = '$_homeRoot/home_astrology.webp';
  static const String homeYildizname = '$_homeRoot/home_yildizname.webp';
  static const String homeCoffee = '$_homeRoot/home_coffee.webp';
  static const String homePalm = '$_homeRoot/home_palm.webp';
  static const String homeSoulMate = '$_homeRoot/home_soulmate.webp';
  static const String homePremium = '$_homeRoot/home_premium.webp';
  static const String homeGemsBanner = '$_homeRoot/home_gems_banner.webp';

  static const String palmRitualHero = '$_imagesRoot/palm_ritual_hero.webp';

  static const String _profileRoot = '$_imagesRoot/profile';
  static const String profileJournalHero =
      '$_profileRoot/profile_journal_hero.webp';
  static const String profileSoulMatePlaceholder =
      '$_profileRoot/profile_soulmate_placeholder.webp';

  static const String _astrologyRoot = '$_imagesRoot/astrology';
  static const String astrologyInstrumentPlate =
      '$_astrologyRoot/astrology_instrument_plate.webp';
  static const String astrologyObservatoryBg =
      '$_astrologyRoot/astrology_observatory_bg.webp';
  static const String astrologyHeroWheel =
      '$_astrologyRoot/astrology_hero_wheel.webp';
  static const String _zodiacRoot = '$_astrologyRoot/zodiac';

  /// Illustrated zodiac emblem — unique per tropical sign.
  static String zodiacIllustration(String signId) =>
      '$_zodiacRoot/zodiac_$signId.webp';

  static const List<String> zodiacSignIds = [
    'aries',
    'taurus',
    'gemini',
    'cancer',
    'leo',
    'virgo',
    'libra',
    'scorpio',
    'sagittarius',
    'capricorn',
    'aquarius',
    'pisces',
  ];

  static const String _yildiznameRoot = '$_imagesRoot/yildizname';
  static const String yildiznameHero =
      '$_yildiznameRoot/yildizname_archive_plate.webp';
  static const String yildiznameArchiveBg =
      '$_yildiznameRoot/yildizname_archive_bg.webp';

  static const String _premiumRoot = '$_imagesRoot/premium';
  static const String premiumChamberHero =
      '$_premiumRoot/premium_chamber_hero.webp';
  static const String premiumGemstone = '$_premiumRoot/premium_gemstone.webp';

  // ── UI icons (simple vector/line art allowed) ─────────────────────
  static const String featureTarot = '$_iconsRoot/feature_tarot.png';
  static const String featureDream = '$_iconsRoot/feature_dream.png';
  static const String featureAstrology = '$_iconsRoot/feature_astrology.png';
  static const String featureStarMap = '$_iconsRoot/feature_star_map.png';
  static const String featureAiCrystal = '$_iconsRoot/feature_ai_crystal.png';
}
