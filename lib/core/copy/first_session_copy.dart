/// RC-012 — Warm, human copy for the first session.
library;

abstract final class FirstSessionCopy {
  FirstSessionCopy._();

  // Home greeting (same layout — different words)
  static const homeGreeting = 'Hoş geldin,';
  static const homeGuestName = 'Yolcu';
  static const homeSubtitleNew =
      'İlk adımın basit: bir kart, bir nefes, bir düşünce.';
  static const homeSubtitleReturning =
      'Kaldığın yerden devam edebilirsin.';

  // Intention
  static const intentionTitle = 'Bugün ne düşünüyorsun?';
  static const intentionSubtitle =
      'Bir konu seç — zorunlu değil, sadece odak için. '
      'İstediğin zaman atlayabilirsin.';

  static const intentionTitleDefault = 'Odak için bir konu';
  static const intentionSubtitleDefault =
      'İstersen bir konu seç — zorunlu değil.';

  // Shuffle
  static const shuffleMessage = 'Kartlar karışıyor. Bir an nefes al.';
  static const shuffleMessageDefault = 'Kartlar hazırlanıyor…';

  // Card selection
  static const cardSelectionTitle = 'İlk kartın.';
  static const cardSelectionSubtitle =
      'Sezgine güven — doğru ya da yanlış kart yok.';
  static const cardSelectionTitleDefault = 'Seni çağıran kartı seç.';
  static const cardSelectionSubtitleDefault = 'Sezgilerine güven.';

  // Reveal → reading
  static const revealContinue = 'Yorumuna geç';
  static const revealContinueDefault = 'Yorumu Gör';

  // Reading intro
  static const introBreath = 'Bir an nefes al…';
  static const introPreparingFirst =
      'Bu bir kehanet değil — düşünmek için bir davet.';
  static const introPreparingDefault =
      'Yorumun sakin bir tempoda açılıyor.';

  static String intentionTitleFor({required bool isFirstSession}) =>
      isFirstSession ? intentionTitle : intentionTitleDefault;

  static String intentionSubtitleFor({required bool isFirstSession}) =>
      isFirstSession ? intentionSubtitle : intentionSubtitleDefault;

  static String shuffleMessageFor({required bool isFirstSession}) =>
      isFirstSession ? shuffleMessage : shuffleMessageDefault;

  static String cardSelectionTitleFor({required bool isFirstSession}) =>
      isFirstSession ? cardSelectionTitle : cardSelectionTitleDefault;

  static String cardSelectionSubtitleFor({required bool isFirstSession}) =>
      isFirstSession ? cardSelectionSubtitle : cardSelectionSubtitleDefault;

  static String revealContinueFor({required bool isFirstSession}) =>
      isFirstSession ? revealContinue : revealContinueDefault;

  static String introPreparingFor({required bool isFirstSession}) =>
      isFirstSession ? introPreparingFirst : introPreparingDefault;
}
