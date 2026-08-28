/// OR natural humor & rhythm — smile when it fits; never a comedian.
library;

import '../l10n/l10n.dart';
import 'or_emotional_intelligence.dart';

/// Whether this turn invites playfulness.
enum OrHumorStance {
  /// User is light / joking / absurd — smile with them.
  welcome,

  /// Ordinary chat — restrained wit only if it arises naturally.
  neutral,

  /// Serious affect or weight — no humor injection.
  serious,
}

/// Restrained humor + conversational rhythm for the live provider.
abstract final class OrNaturalHumor {
  OrNaturalHumor._();

  static String get promptRule => switch (OraclyL10n.code) {
        'en' => promptEn,
        'ru' => promptRu,
        _ => promptTr,
      };

  static const promptTr =
      'Mizah tutumlu olsun: bağlam uygunsa kullanıcıyla gülümsenebilir, '
      'hafif ironi, absürtlüğü fark etme veya oyunbaz bir dokunuş serbest. '
      'Ciddi ana mizah sokma. Komedyen olma; espri yağmuruna tutulma. '
      'Amaç doğal sohbet. Ritmi değiştir — her yanıtı aynı uzunlukta yazma.';

  static const promptEn =
      'Keep humor restrained: when context supports it, you may smile with '
      'the user, use light irony, acknowledge absurdity, or answer playfully. '
      'Do not inject humor into serious moments. Never become a comedian; '
      'no joke storms. Goal: natural conversation. Vary rhythm — do not make '
      'every reply the same length.';

  static const promptRu =
      'Юмор сдержанный: если контекст позволяет, можно улыбнуться с '
      'пользователем, лёгкая ирония, заметить абсурд или ответить игриво. '
      'Не вставляй юмор в серьёзные моменты. Не становись комиком; '
      'без ливня шуток. Цель: живой разговор. Меняй ритм — не пиши '
      'каждый ответ одной длины.';

  static OrHumorStance stanceFor(String text) {
    final t = text.trim();
    if (t.isEmpty) return OrHumorStance.neutral;
    final signals = OrEmotionalIntelligence.sense(t).signals;
    if (signals.contains(OrEmotionalSignal.sadness) ||
        signals.contains(OrEmotionalSignal.anger) ||
        signals.contains(OrEmotionalSignal.frustration) ||
        _heavy(t.toLowerCase())) {
      return OrHumorStance.serious;
    }
    if (signals.contains(OrEmotionalSignal.humor) ||
        signals.contains(OrEmotionalSignal.excitement) ||
        _lightAbsurd(t.toLowerCase())) {
      return OrHumorStance.welcome;
    }
    return OrHumorStance.neutral;
  }

  /// Per-turn hint only when stance is not neutral.
  static String? styleHintFor(String text) {
    return switch (stanceFor(text)) {
      OrHumorStance.welcome => switch (OraclyL10n.code) {
          'en' =>
            'Humor welcome: smile with the user; light irony OK; '
                'never a comedian set.',
          'ru' =>
            'Юмор уместен: улыбнись с пользователем; лёгкая ирония OK; '
                'не комик-номер.',
          _ =>
            'Mizah uygun: kullanıcıyla gülümse; hafif ironi tamam; '
                'komedyen seti yok.',
        },
      OrHumorStance.serious => switch (OraclyL10n.code) {
          'en' =>
            'Serious moment: no jokes, no irony, stay present and steady.',
          'ru' =>
            'Серьёзный момент: без шуток и иронии; будь рядом и спокоен.',
          _ =>
            'Ciddi an: espri yok, ironi yok; sakin ve yanında kal.',
        },
      OrHumorStance.neutral => null,
    };
  }

  /// Stand-up / joke-storm tone in model output — reject for companion.
  static bool looksLikeComedian(String text) {
    final lower = text.toLowerCase();
    var hits = 0;
    const markers = [
      'bir espri daha',
      'here is a joke',
      'knock knock',
      'why did the',
      'punchline',
      'hahaha',
      'let me tell you a joke',
      'bir fıkra',
      'bir fikra',
    ];
    for (final m in markers) {
      if (lower.contains(m)) hits++;
    }
    if (lower.contains('😂😂')) hits++;
    if (RegExp(r'(! ){3,}').hasMatch(text) || RegExp(r'!{3,}').hasMatch(text)) {
      hits++;
    }
    return hits >= 2;
  }

  static bool _heavy(String lower) =>
      lower.contains('ölüm') ||
      lower.contains('olum') ||
      lower.contains('hastalık') ||
      lower.contains('hastalik') ||
      lower.contains('korkuyorum') ||
      lower.contains('grief') ||
      lower.contains('funeral') ||
      lower.contains('смерть') ||
      lower.contains('болезн');

  static bool _lightAbsurd(String lower) =>
      lower.contains('saçma') ||
      lower.contains('sacma') ||
      lower.contains('absürt') ||
      lower.contains('absurd') ||
      lower.contains('komik değil mi') ||
      lower.contains('komik degil mi') ||
      lower.contains('ridiculous') ||
      lower.contains('смешн');
}
