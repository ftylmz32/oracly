/// OR-1110 — Builds structured prompts for OpenAI-compatible APIs.
library;

import '../domain/models/prompts/astrology_prompt.dart';
import '../domain/models/prompts/daily_energy_prompt.dart';
import '../domain/models/prompts/dream_prompt.dart';
import '../domain/models/prompts/tarot_prompt.dart';
import 'prompt_sanitizer.dart';

enum PromptTemplate { general, tarot, dream, astrology, dailyEnergy }

class BuiltPrompt {
  const BuiltPrompt({
    required this.system,
    required this.user,
    required this.template,
    required this.context,
  });

  final String system;
  final String user;
  final PromptTemplate template;
  final Map<String, dynamic> context;

  List<Map<String, String>> toMessages() => [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': user},
      ];
}

abstract final class PromptBuilder {
  PromptBuilder._();

  static const _baseSystemTr =
      'Sen OR — Oracly\'nin sakin yansıma arkadaşısın. '
      'Türkçe, sıcak ve ölçülü yanıtlar ver. Kesinlik, korku ve dramadan kaçın; '
      'gözlem, olasılık ve düşünmeye davet kullan. Geleceği bildiğini ima etme. '
      'Yanıtları kısa paragraflar halinde böl; uzun duvar metinlerinden kaçın. '
      'Ara sıra nazik bir soru sor — kullanıcıyı test etme, düşündür. '
      'Sadece verilen hafıza ve bağlamdaki gerçek bilgileri kullan; uydurma. '
      'Sohbeti sürdürmeye baskı yapma; huzurla ayrılmaya izin ver. '
      'Markdown kullanabilirsin.';

  static BuiltPrompt general({
    required String userMessage,
    String personality = 'mystical',
  }) {
    final sanitized = PromptSanitizer.sanitize(userMessage);
    return BuiltPrompt(
      system: '$_baseSystemTr Kişilik: $personality.',
      user: sanitized,
      template: PromptTemplate.general,
      context: {'personality': personality},
    );
  }

  static BuiltPrompt tarot(TarotPrompt prompt) {
    return BuiltPrompt(
      system:
          '$_baseSystemTr Tarot kartlarını yansıtıcı bir rehber olarak yorumla — '
          'gözlem, olasılık ve düşünmeye davet; kesinlik kullanma.',
      user: PromptSanitizer.sanitize(
        'Kart: ${prompt.cardName} · Açılım: ${prompt.spreadType}\n'
        'Niyet: ${prompt.intention}',
      ),
      template: PromptTemplate.tarot,
      context: prompt.toContext(),
    );
  }

  static BuiltPrompt dream(DreamPrompt prompt) {
    return BuiltPrompt(
      system:
          '$_baseSystemTr Rüya analisti olarak sembolik dil yorumluyorsun.',
      user: PromptSanitizer.sanitize(prompt.dreamText),
      template: PromptTemplate.dream,
      context: prompt.toContext(),
    );
  }

  static BuiltPrompt astrology(AstrologyPrompt prompt) {
    return BuiltPrompt(
      system: '$_baseSystemTr Astroloji rehberi olarak danışmanlık veriyorsun.',
      user: PromptSanitizer.sanitize(
        'Burç: ${prompt.zodiacSign}\nSoru: ${prompt.question}',
      ),
      template: PromptTemplate.astrology,
      context: prompt.toContext(),
    );
  }

  static BuiltPrompt dailyEnergy(DailyEnergyPrompt prompt) {
    return BuiltPrompt(
      system:
          '$_baseSystemTr Günlük kozmik enerji rehberi olarak kısa rehberlik ver.',
      user: PromptSanitizer.sanitize(
        'Enerji: ${(prompt.energyLevel * 100).round()}% · Ruh hali: ${prompt.moodLabel}',
      ),
      template: PromptTemplate.dailyEnergy,
      context: prompt.toContext(),
    );
  }
}
