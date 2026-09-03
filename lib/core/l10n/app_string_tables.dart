/// Merged production string tables — every key has TR, EN, and RU.
library;

import 'app_locale.dart';
import 'l10n_triple.dart';
import 'tables/table_astrology.dart';
import 'tables/table_birth.dart';
import 'tables/table_birth_more.dart';
import 'tables/table_birth_insight.dart';
import 'tables/table_chrome.dart';
import 'tables/table_coffee.dart';
import 'tables/table_companion.dart';
import 'tables/table_cup_read.dart';
import 'tables/table_discovery_comparison.dart';
import 'tables/table_discovery_revisit.dart';
import 'tables/table_daily_return.dart';
import 'tables/table_daily_ritual.dart';
import 'tables/table_dream.dart';
import 'tables/table_dream_more.dart';
import 'tables/table_dream_read.dart';
import 'tables/table_economy.dart';
import 'tables/table_explore.dart';
import 'tables/table_features.dart';
import 'tables/table_format.dart';
import 'tables/table_favorite_moments.dart';
import 'tables/table_first.dart';
import 'tables/table_fortune.dart';
import 'tables/table_fortune_symbols.dart';
import 'tables/table_home.dart';
import 'tables/table_home_phrases.dart';
import 'tables/table_help.dart';
import 'tables/table_insight_copy.dart';
import 'tables/table_insights.dart';
import 'tables/table_legal.dart';
import 'tables/table_or_chat.dart';
import 'tables/table_or_core.dart';
import 'tables/table_or_living.dart';
import 'tables/table_or_menu.dart';
import 'tables/table_or_voice.dart';
import 'tables/table_palm.dart';
import 'tables/table_palm_read.dart';
import 'tables/table_premium.dart';
import 'tables/table_privacy_control.dart';
import 'tables/table_profile.dart';
import 'tables/table_quality_loop.dart';
import 'tables/table_reader.dart';
import 'tables/table_reading_feedback.dart';
import 'tables/table_reading_ux.dart';
import 'tables/table_reading_version.dart';
import 'tables/table_recommendation.dart';
import 'tables/table_oracle_core.dart';
import 'tables/table_release_paths.dart';
import 'tables/table_notify.dart';
import 'tables/table_resilience.dart';
import 'tables/table_safety.dart';
import 'tables/table_screens.dart';
import 'tables/table_session_continuation.dart';
import 'tables/table_share_reopen.dart';
import 'tables/table_sky_more.dart';
import 'tables/table_sky_read.dart';
import 'tables/table_soulmate.dart';
import 'tables/table_star_archive.dart';
import 'tables/table_star_voice.dart';
import 'tables/table_tarot.dart';
import 'tables/table_tarot_destem.dart';
import 'tables/table_tarot_flow.dart';
import 'tables/table_tarot_hist.dart';
import 'tables/table_tarot_intent.dart';
import 'tables/table_tarot_minors.dart';
import 'tables/table_tarot_oracle.dart';
import 'tables/table_tarot_read.dart';
import 'tables/table_tarot_story.dart';
import 'tables/table_theme_copy.dart';
import 'tables/table_trust.dart';
import 'tables/table_universe.dart';
import 'tables/table_voice.dart';
import 'tables/table_zodiac.dart';

abstract final class AppStringTables {
  AppStringTables._();

  static const Map<String, L10nTriple> all = {
    ...kL10nChrome,
    ...kL10nCoffee,
    ...kL10nOrCore,
    ...kL10nOrLiving,
    ...kL10nPalm,
    ...kL10nPalmRead,
    ...kL10nPremium,
    ...kL10nPrivacyControl,
    ...kL10nQualityLoop,
    ...kL10nResilience,
    ...kL10nSafety,
    ...kL10nSoulMate,
    ...kL10nStarVoice,
    ...kL10nStarArchive,
    ...kL10nCompanion,
    ...kL10nAstrology,
    ...kL10nZodiac,
    ...kL10nTarot,
    ...kL10nTarotDestem,
    ...kL10nTarotFlow,
    ...kL10nTarotMinors,
    ...kL10nTarotRead,
    ...kL10nTarotOracle,
    ...kL10nTarotStory,
    ...kL10nTarotIntent,
    ...kL10nTarotHist,
    ...kL10nHome,
    ...kL10nHelp,
    ...kL10nLegal,
    ...kL10nFirst,
    ...kL10nFortune,
    ...kL10nFortuneSymbols,
    ...kL10nProfile,
    ...kL10nReader,
    ...kL10nReadingFeedback,
    ...kL10nReadingUx,
    ...kL10nReadingVersion,
    ...kL10nCupRead,
    ...kL10nDailyReturn,
    ...kL10nDailyRitual,
    ...kL10nSkyRead,
    ...kL10nSkyMore,
    ...kL10nRecommendation,
    ...kL10nOracleCore,
    ...kL10nReleasePaths,
    ...kL10nSessionContinuation,
    ...kL10nNotify,
    ...kL10nDiscoveryRevisit,
    ...kL10nDiscoveryComparison,
    ...kL10nFavoriteMoments,
    ...kL10nDream,
    ...kL10nDreamMore,
    ...kL10nDreamRead,
    ...kL10nBirth,
    ...kL10nBirthMore,
    ...kL10nBirthInsight,
    ...kL10nVoice,
    ...kL10nUniverse,
    ...kL10nOrChat,
    ...kL10nOrMenu,
    ...kL10nOrVoice,
    ...kL10nTrust,
    ...kL10nEconomy,
    ...kL10nExplore,
    ...kL10nHomePhrases,
    ...kL10nThemeCopy,
    ...kL10nScreens,
    ...kL10nShareReopen,
    ...kL10nInsightCopy,
    ...kL10nInsights,
    ...kL10nFeatures,
    ...kL10nFormat,
  };

  static String? lookup(String code, String key) => all[key]?.of(code);

  static Iterable<String> get keys => all.keys;

  static Map<String, String> flattened(String code) => {
    for (final e in all.entries) e.key: e.value.of(code),
  };
}

abstract final class AppLocaleTables {
  AppLocaleTables._();

  static Map<String, String> forCode(String code) =>
      AppStringTables.flattened(AppLocale.normalize(code));
}
