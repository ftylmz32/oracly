/// OR-1110 — Mock AI response catalogue.
library;

abstract final class MockAIResponses {
  MockAIResponses._();

  static const generalGreeting =
      'Merhaba! Ben OR — sezgisel rehberin. Bugün kalbin hangi soruyu taşıyor?';

  static String tarotInterpretation(String card, String spread) =>
      '**$card** kartı $spread açılımında güçlü bir mesaj taşıyor.\n\n'
      'Genel anlam: Evren senin niyetini duyuyor. İç sesine güven; '
      'yolculuğun doğru yönde ilerliyor.\n\n'
      '> "Kartlar konuşur — dinleyen kalp anlar."';

  static String dreamAnalysis(String excerpt) =>
      'Rüyanda öne çıkan imgeler bir araya geldiğinde, '
      'gündüz düşüncelerinle sessiz bir diyalog kuruyor olabilir. '
      'Bu yalnızca bir olasılık — senin bağlamın en doğru rehber.\n\n'
      'Kısa not: "$excerpt" ifadesi dikkat çekici bir tema taşıyor.';

  static String astrologyReading(String sign, String question) =>
      '$sign enerjisi, $question konusunda farkındalık için bir ayna olabilir. '
      'Bu yalnızca bir olasılık — kendi deneyimin en doğru rehber.';

  static String dailyEnergyGuidance(double level, String mood) =>
      'Bugünkü kozmik enerjin **${(level * 100).round()}%** — $mood titreşiminde.\n\n'
      'Sabah niyetini belirle; akşam minnettarlık pratiği ruhsal seviyeni dengeleyecek.';

  static const streamingChunks = [
    'OR ',
    'senin ',
    'iç ',
    'sesini ',
    'dinliyor',
    '... ',
    'Evren ',
    'cevap ',
    'veriyor.',
  ];

  static const suggestedFollowUps = [
    'Bu mesajı derinleştir',
    'Aşk hayatım için ne söylüyorsun?',
    'Bugün için bir tavsiye ver',
  ];
}
