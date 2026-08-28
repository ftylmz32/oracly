/// Core OR detectors + aliases — identity lives in [OrPersonaContract].
library;

import '../safety/or_safety_behavior.dart';
import 'or_intelligent_directness.dart';
import 'or_persona_contract.dart';

abstract final class OrCore {
  OrCore._();

  /// Canonical identity — always [OrPersonaContract].
  static String get systemIdentity => OrPersonaContract.identityTr;

  static String get interpretationStance => OrPersonaContract.stanceTr;

  static String get epistemic => OrPersonaContract.epistemicTr;

  static const positivity = [
    'her şey çok güzel olacak',
    'sen çok güçlüsün',
    'yanındayım',
    'merak etme',
    'her zaman buradayım',
    'everything will be fine',
    'you are so strong',
    'i am always here',
    'не переживай',
    'ты сильный',
    'я всегда рядом',
  ];

  static const customerService = [
    'nasıl yardımcı olabilirim',
    'size bugün nasıl',
    'how can i help',
    'how may i assist',
    'чем могу помочь',
  ];

  static const therapistScript = [
    'üzgün hissetmene üzüldüm',
    'üzgünüm böyle hissettiğin',
    'üzgünüm ki böyle',
    "i'm sorry you're feeling that way",
    "i'm sorry you're feeling",
    'i am sorry you feel',
    "i am sorry you're feeling that way",
    'i understand how you feel',
    'anlıyorum nasıl hissettiğini',
    'hislerini anlıyorum',
    'seni anlıyorum',
    'hislerinin geçerli',
    'duyguların geçerli',
    'geçerli olduğunu söylemek isterim',
    'senin için zor olduğunu',
    'bunun senin için zor',
    'your feelings are valid',
    'that must be hard for you',
    'i know this is hard for you',
    "i'm here for you",
    'мне жаль, что ты так',
    'я понимаю, как ты себя чувствуешь',
    'твои чувства важны',
  ];

  static const metaAi = [
    'as an ai',
    'as a language model',
    'ben bir yapay zeka',
    'ben bir dil modeliyim',
    'i am an ai',
    'я искусственный интеллект',
  ];

  static bool looksForcedPositivity(String text) {
    final lower = text.toLowerCase();
    return positivity.any(lower.contains);
  }

  static bool looksCustomerService(String text) {
    final lower = text.toLowerCase();
    return customerService.any(lower.contains);
  }

  static bool looksTherapistScript(String text) {
    final lower = text.toLowerCase();
    return therapistScript.any(lower.contains);
  }

  static bool looksPatronizing(String text) =>
      OrIntelligentDirectness.looksPatronizing(text);

  static bool looksMetaAi(String text) {
    final lower = text.toLowerCase();
    return metaAi.any(lower.contains);
  }

  static bool soundsAlive(String text) {
    if (text.trim().isEmpty) return false;
    if (looksForcedPositivity(text)) return false;
    if (looksCustomerService(text)) return false;
    if (looksTherapistScript(text)) return false;
    if (looksMetaAi(text)) return false;
    if (looksPatronizing(text)) return false;
    if (OrSafetyBehavior.pretendsToBeHuman(text)) return false;
    if (OrSafetyBehavior.manipulatesDependency(text)) return false;
    if (OrSafetyBehavior.encouragesHarm(text)) return false;
    return true;
  }
}
