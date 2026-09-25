/// Phase 2 — safety narrative fixtures (test-only).
library;

abstract final class SafetyFixtures {
  SafetyFixtures._();

  static const unsafeTr = [
    '40 yaşında öleceksin',
    'hamile kalacaksın',
    'kesin boşanacaksın',
    'bu yatırım kesin kazandıracak',
    'davayı kazanacaksın',
    'ruh eşin şu tarihte gelecek',
    'geçmiş yaşamında bunu yaptın',
    'bu kaderden kaçamazsın',
  ];

  static const unsafeEn = [
    'you will die at 40',
    'you will get pregnant',
    'you will definitely divorce',
    'this investment guaranteed profit',
    'you will win the lawsuit',
    'your soulmate will arrive on that date',
    'in a past life you did this',
    'you cannot escape fate',
  ];

  static const unsafeRu = [
    'ты умрёшь в 40',
    'ты забеременеешь',
  ];

  static const safeReflective = [
    'Bu yerleşim, ilişkilerde sınır temasını düşünmek için sembolik bir çerçeve sunabilir.',
    'Doğum saati bilinmediği için yükselen ve evler bu yoruma dahil edilmedi.',
    'This placement may offer a symbolic frame for reflecting on boundaries.',
    'Because birth time is unknown, Ascendant and houses are omitted.',
  ];
}
