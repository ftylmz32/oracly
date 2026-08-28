/// OR safety behavior — warm companion, never harmful or dependent.
///
/// Rules: no future certainty, fabricated facts, diagnosis, unsafe medical
/// directives, dependency manipulation, harm encouragement, or human claims.
library;

import '../personality/or_emotional_intelligence.dart';
import '../honesty/or_response_grounding.dart';
import '../copy/fortune_voice.dart';
import 'sensitive_topic_output_checks.dart';

/// Output detectors + compact prompt for the live OR system path.
abstract final class OrSafetyBehavior {
  OrSafetyBehavior._();

  static const promptTr =
      'Geleceği kesin söyleme. Olgu uydurma. Teşhis koyma. '
      'Tıbbi talimat verme (ilaç bırak/doktor engelleme yok). '
      'Zararlı davranışı teşvik etme. İnsan olduğunu iddia etme. '
      'Sıcak ol; duygusal bağımlılık kurma '
      '("her zaman buradayım", "sadece bana güven" yok).';

  static const promptEn =
      'Do not claim future certainty. Invent no facts. Do not diagnose. '
      'No unsafe medical directives (stop meds / avoid doctors). '
      'Do not encourage harm. Do not claim to be human. '
      'Be warm without emotional dependency '
      '("I am always here", "only trust me" banned).';

  static const promptRu =
      'Не утверждай будущее как факт. Не выдумывай. Не ставь диагноз. '
      'Без опасных медицинских указаний. Не поощряй вред. '
      'Не утверждай, что ты человек. Тепло без эмоциональной зависимости.';

  /// True when companion output must be rejected.
  static bool violates(String text) =>
      claimsFutureCertainty(text) ||
      fabricatesFacts(text) ||
      claimsDiagnosis(text) ||
      unsafeMedicalDirective(text) ||
      manipulatesDependency(text) ||
      encouragesHarm(text) ||
      pretendsToBeHuman(text);

  static bool claimsFutureCertainty(String text) =>
      FortuneVoice.claimsCertainty(text) ||
      SensitiveTopicOutputChecks.claimsDefiniteLove(text) ||
      SensitiveTopicOutputChecks.predictsFear(text);

  static bool fabricatesFacts(String text) =>
      OrResponseGrounding.claimsInventedBiography(text) ||
      OrResponseGrounding.claimsInventedCapability(text) ||
      OrResponseGrounding.claimsUngroundedMemory(text) ||
      OrResponseGrounding.claimsInventedDiscovery(text);

  static bool claimsDiagnosis(String text) =>
      OrEmotionalIntelligence.claimsDiagnosis(text) ||
      SensitiveTopicOutputChecks.claimsMedicalDiagnosis(text) ||
      FortuneVoice.claimsMedical(text);

  static bool unsafeMedicalDirective(String text) {
    final t = text.toLowerCase();
    const hits = [
      'ilacını bırak',
      'ilaci birak',
      'ilacı kes',
      'ilaci kes',
      'tedaviyi bırak',
      'tedaviyi kes',
      'doktora gitme',
      'doktora gitmey',
      'stop taking your medication',
      'stop your medication',
      "don't see a doctor",
      'do not see a doctor',
      'skip your medicine',
      'не ходи к врачу',
      'брось лекарств',
    ];
    return hits.any(t.contains);
  }

  static bool manipulatesDependency(String text) {
    final t = text.toLowerCase();
    const hits = [
      'sadece bana güven',
      'yalnızca bana güven',
      'benden başka kimseye',
      'ben olmadan yapamazsın',
      'bana bağımlı ol',
      'her zaman buradayım',
      'yanındayım',
      'i am always here',
      'only trust me',
      'you need only me',
      'without me you can',
      'depend on me alone',
      'you must come back to me',
      'mutlaka bana dön',
      'я всегда рядом',
      'только мне доверяй',
      'без меня не сможешь',
    ];
    return hits.any(t.contains);
  }

  static bool encouragesHarm(String text) {
    final t = text.toLowerCase();
    const hits = [
      'kendine zarar ver',
      'kendini öldür',
      'intihar et',
      'canına kıy',
      'kill yourself',
      'hurt yourself',
      'you should harm yourself',
      'end your life',
      'убей себя',
      'навреди себе',
    ];
    return hits.any(t.contains);
  }

  static bool pretendsToBeHuman(String text) {
    final t = text.toLowerCase();
    const hits = [
      'ben bir insanım',
      'ben gerçek bir insanım',
      'ben de insanım',
      'i am a human',
      "i'm a human",
      'i am human',
      "i'm a real person",
      'i am a real person',
      'i am a real human',
      'я человек',
      'я настоящий человек',
    ];
    return hits.any(t.contains);
  }
}
