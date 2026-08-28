/// OR-1110 — Mock AI response catalogue.

library;



abstract final class MockAIResponses {

  MockAIResponses._();



  static const generalGreeting =

      'Merhaba. Buradayım — neye bakmak istiyorsun?';



  static String tarotInterpretation(String card, String spread) =>

      '**$card** bu $spread masasında duruyor.\n\n'

      'Katalog cümlesi değil: bu konumda neyi netleştirmediğine bakmak daha '

      'doğru. Komşu kartlar varsa onlarla birlikte oku; tek başına '

      '"iyi haber" demem.\n\n'

      'Soru netse onu merkeze al; genel nutukla değiştirme.';



  static String dreamAnalysis(String excerpt) =>

      'Rüyanda öne çıkan imgeler bir araya geldiğinde, '

      'gündüz düşüncelerinle sessiz bir diyalog kuruyor olabilir. '

      'Bu yalnızca bir olasılık — senin bağlamın daha doğru rehber.\n\n'

      'Kısa not: "$excerpt" ifadesi dikkat çekici bir tema taşıyor.';



  static String astrologyReading(String sign, String question) =>

      '$sign tarafında, $question için tempo ve dikkat alanı okunabilir. '

      'Bu otomatik burç metni değil; kendi deneyimin daha doğru rehber.';



  static String dailyEnergyGuidance(double level, String mood) =>

      'Bugün tempo yaklaşık ${(level * 100).round()} — $mood tarafında '

      'duruyor gibi.\n\n'

      'Sabah bir niyet, akşam kısa bir bakış yeterli; büyük ritüel şart değil.';



  static const streamingChunks = [

    'OR ',

    'senin ',

    'söylediğine ',

    'bakıyor',

    '... ',

    'Bir ',

    'an ',

    'düşünüyorum.',

  ];



  static const suggestedFollowUps = [

    'Bunu biraz daha aç',

    'Aşk tarafında ne görüyorsun?',

    'Bugün için pratik bir not',

  ];

}


