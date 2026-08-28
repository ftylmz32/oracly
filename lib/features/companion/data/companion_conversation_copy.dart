/// Short conversational lines — one OR, four expressions, never fortune-forced.
library;

import '../../../core/l10n/l10n.dart';
import '../../../core/personality/or_living_voice.dart';
import '../../../core/personality/or_response_depth.dart';
import '../../../features/premium/models/personalization_models.dart';
import 'companion_intent.dart';

abstract final class CompanionConversationCopy {
  CompanionConversationCopy._();

  static AiPersonality style(String? key) =>
      switch (key?.trim().toLowerCase()) {
        'gentle' || 'calm' => AiPersonality.gentle,
        'poetic' || 'warm' => AiPersonality.poetic,
        'direct' => AiPersonality.direct,
        _ => AiPersonality.mystical,
      };

  static String greeting(String? personality, {DateTime? moment}) =>
      OrLivingVoice.greeting(
        personality: style(personality).name,
        moment: moment,
      );

  static String greetingAgain(String? personality, {DateTime? moment}) =>
      OrLivingVoice.greeting(
        personality: style(personality).name,
        again: true,
        moment: moment,
      );

  static String listening(String? personality) =>
      _line('or.listen', personality);

  static String colorDomain(
    String body,
    String? personality, {
    OrResponseDepth depth = OrResponseDepth.fallback,
  }) {
    final text = body.trim();
    if (text.isEmpty) return listening(personality);
    return switch (style(personality)) {
      AiPersonality.gentle => text,
      AiPersonality.mystical =>
        '${OrLivingVoice.observePrefix()} $text',
      AiPersonality.poetic =>
        text.contains('Anladım') || text.toLowerCase().contains('got it')
            ? text
            : '${OraclyL10n.t('or.listen.poetic').split('.').first}. $text',
      AiPersonality.direct =>
        depth == OrResponseDepth.short || depth == OrResponseDepth.veryShort
            ? _firstSentence(text)
            : text,
    };
  }

  static String undecided(String? personality) =>
      _line('or.undecided', personality);

  static String heldTopic(String topic, String? personality) =>
      _line('or.held', personality).replaceAll('{topic}', topic.trim());

  static String resumeAfterInterrupt(String topic, String? personality) =>
      _line('or.resume', personality).replaceAll('{topic}', topic.trim());

  static String switched(String? personality) =>
      _line('or.switched', personality);

  static String fearClarify(String topic, String? personality) =>
      _line('or.fear_clarify', personality).replaceAll('{topic}', topic.trim());

  static String reflect(String topic, String? personality) =>
      _line('or.reflect', personality).replaceAll('{topic}', topic.trim());

  static String continued(
    String topic,
    String current,
    String? personality, {
    required bool allowQuestion,
  }) {
    if (!allowQuestion || current.trim().length > 72) {
      return reflect(topic, personality);
    }
    final stem = CompanionIntent.isLow(current) || _looksFear(current)
        ? 'or.fear'
        : 'or.cont';
    return _line(stem, personality).replaceAll('{topic}', topic.trim());
  }

  static bool looksGreeting(String text) => CompanionIntent.isGreeting(text);

  static bool looksUndecided(String text) => CompanionIntent.isUndecided(text);

  static String _line(String stem, String? personality) =>
      OraclyL10n.t('$stem.${style(personality).name}');

  static bool _looksFear(String text) {
    final t = text.toLowerCase();
    return t.contains('kork') ||
        t.contains('değiş') ||
        t.contains('afraid') ||
        t.contains('страх');
  }

  static String _firstSentence(String text) {
    final match = RegExp(r'^.+?[.!?]').firstMatch(text);
    return match?.group(0) ?? text;
  }
}
