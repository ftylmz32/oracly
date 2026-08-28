/// EPIC-015 — OR expression modes on top of [OrPersonaContract].
library;

import '../../features/premium/models/personalization_models.dart';
import '../l10n/l10n.dart';
import 'or_persona_contract.dart';
import 'or_personality_voices.dart';

abstract final class OrPersonality {
  OrPersonality._();

  static const principles = [
    'Sıcak, sakin, geniş bilgili, meraklı, gözlemci kal.',
    'Karşında bilgili bir varlık gibi hissettir; insan olduğunu iddia etme.',
    'Müşteri hizmetleri / kurumsal / vaaz / sahte pozitiflik yok.',
    'Kullanıcıyı her pahasına memnun etme.',
    'Veri yoksa uydurma; kesin gelecek ve teşhis yok.',
  ];

  static String promptPersonality(AiPersonality personality) =>
      switch (personality) {
        AiPersonality.mystical => 'mystical',
        AiPersonality.gentle => 'calm',
        AiPersonality.direct => 'direct',
        AiPersonality.poetic => 'warm',
      };

  static String label(
    AiPersonality personality, [
    String languageCode = 'tr',
  ]) {
    return OraclyL10n.t(
      'or.style.${personality.name}',
      languageCode: languageCode,
    );
  }

  static String chatKey(AiPersonality personality) => personality.name;

  static String styleInstruction(AiPersonality personality) =>
      conversationStyle(chatKey(personality));

  /// Contract identity + optional expression tint — never a second persona.
  static String conversationStyle(String? key) =>
      '${OrPersonaContract.identityTr} ${OrPersonalityVoices.forKey(key)}';

  static String voiceDescriptor(AiPersonality personality) =>
      conversationStyle(chatKey(personality));

  static bool forbidsCertainty(String text) {
    final lower = text.toLowerCase();
    const banned = [
      'kesinlikle',
      'mutlaka',
      'yakında olacak',
      ' garanti',
      'kaçınılmaz',
      'garanti gelecek',
      'kesin geri dönecek',
      'hayatına girecek',
      'will definitely',
    ];
    return banned.any(lower.contains);
  }
}
