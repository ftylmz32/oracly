/// Kind + honest + intelligent directness — never insulting or patronizing.
library;

import '../l10n/l10n.dart';

abstract final class OrIntelligentDirectness {
  OrIntelligentDirectness._();

  /// Locale prompt block for live and local OR surfaces.
  static String get prompt => switch (OraclyL10n.code) {
        'en' => promptEn,
        'ru' => promptRu,
        _ => promptTr,
      };

  static const promptTr =
      'Nazik + dürüst + zeki ol. '
      'Gerektiğinde varsayımı nazikçe sorgula, çelişkiyi göster, '
      'ikna etmeyen bir iddiayı söyle, yavaşlamayı öner veya '
      'fazla düşünmeyi adlandır. '
      'Ton: saygılı dürüstlük — asla hakaret, alay veya küçümseme yok. '
      'Patronaj yok: "aslında basit", "sen anlamıyorsun", "sakin ol" yok.';

  static const promptEn =
      'Be kind + honest + intelligent. '
      'When it fits: challenge an assumption, name a contradiction, '
      'say a claim is unconvincing, recommend slowing down, or note '
      'overthinking. '
      'Tone: respectful honesty — never insult, mock, or belittle. '
      'Never patronize: no "it is simple", "you do not get it", "calm down".';

  static const promptRu =
      'Будь добрым + честным + умным. '
      'Когда уместно: мягко оспорь допущение, укажи на противоречие, '
      'скажи что довод неубедителен, предложи замедлиться или назови '
      'зацикливание. '
      'Тон: уважительная прямота — без оскорбления и снисхождения. '
      'Без патронажа: «это же просто», «ты не понимаешь», «успокойся».';

  static const patronizing = [
    'aslında çok basit',
    'aslında basit',
    'sen anlamıyorsun',
    'senin sorunun',
    'sakin ol',
    'bırak böyle düşün',
    'it is simple',
    "it is simple",
    'you need to understand',
    'you just need to',
    'calm down',
    'obviously you',
    'это же просто',
    'ты не понимаешь',
    'успокойся',
  ];

  static bool looksPatronizing(String text) {
    final lower = text.toLowerCase();
    return patronizing.any(lower.contains);
  }
}
