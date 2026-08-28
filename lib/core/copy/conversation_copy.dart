/// RC-002 — AI conversation copy: calm companion, not chatbot.
library;

import '../../features/premium/models/personalization_models.dart';
import '../l10n/l10n.dart';
import '../personality/or_conversation_voice.dart';
import '../personality/or_living_voice.dart';

abstract final class ConversationCopy {
  ConversationCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get companionSubtitle => _t('or.conversation_subtitle');
  static String get inputHint => _t('or.input_hint');
  static String get askOr => _t('or.ask');
  static String get oracleInputHint => _t('or.oracle_hint');
  static String get thinkingLabel => OrLivingVoice.thinking();
  static String get oracleThinkingLabel => thinkingLabel;
  static String get oracleUnavailable => _t('resilience.ai_unavailable');
  static String get oracleEmptyTitle => _t('or.empty_title');
  static String get oracleEmptyBody => _t('or.empty_body');

  static String closingWhisper({DateTime? moment}) =>
      OrConversationVoice.outro(moment: moment ?? DateTime.now());

  static String welcome({
    String? name,
    AiPersonality personality = AiPersonality.mystical,
    DateTime? moment,
  }) {
    return OrConversationVoice.intro(
      name: name,
      personality: personality,
      moment: moment ?? DateTime.now(),
    );
  }

  static List<String> get oracleSuggestions => [
        _t('or.sug.tarot.0'),
        _t('or.sug.tarot.1'),
        _t('or.sug.tarot.2'),
      ];
  static List<String> get coffeeOracleSuggestions => [
        _t('or.sug.coffee.0'),
        _t('or.sug.coffee.1'),
        _t('or.sug.coffee.2'),
      ];
  static List<String> get dreamOracleSuggestions => [
        _t('or.sug.dream.0'),
        _t('or.sug.dream.1'),
        _t('or.sug.dream.2'),
      ];
  static List<String> get astrologyOracleSuggestions => [
        _t('or.sug.astro.0'),
        _t('or.sug.astro.1'),
        _t('or.sug.astro.2'),
      ];
  static List<String> get birthChartOracleSuggestions => [
        _t('or.sug.chart.0'),
        _t('or.sug.chart.1'),
        _t('or.sug.chart.2'),
      ];

  static String get coffeeOracleEmptyTitle => _t('or.coffee_empty_title');
  static String get coffeeOracleEmptyBody => _t('or.coffee_empty_body');
  static String get dreamOracleEmptyTitle => _t('or.dream_empty_title');
  static String get dreamOracleEmptyBody => _t('or.dream_empty_body');
  static String get astrologyOracleEmptyTitle => _t('or.astro_empty_title');
  static String get astrologyOracleEmptyBody => _t('or.astro_empty_body');
  static String get chartOracleEmptyTitle => _t('or.chart_empty_title');
  static String get chartOracleEmptyBody => _t('or.chart_empty_body');
}
