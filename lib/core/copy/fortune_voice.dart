/// Shared fortune-reading voice — honest, specific, never robotic filler.
library;

abstract final class FortuneVoice {
  FortuneVoice._();

  static const robotic = [
    'ön plana çıkabilir',
    'öne çıkabilir',
    'öne çıkan enerji',
    'gündeme gelebilir',
    'enerjisi hissedilebilir',
    'fırsatlar doğabilir',
    'iletişim ön plana',
    'duygusal gelişmeler olabilir',
    'duygusal bir hareketlilik',
    'yeni fırsatlar gündeme gelebilir',
    'yeni fırsatlar olabilir',
    'kariyer alanınızda değişim',
    'bugün harika bir gün',
    'değişim enerjisi',
    'kariyer hayatınızda',
    'bugün sizin için',
    'evren size',
    'fırsatlar kapıda',
    'dönüşüm enerjisi',
    'analiz tamamlandı',
    'iç sesine güven',
    'kozmik enerji',
    'yolculuğun doğru',
    'evren senin',
    'farkındalık açısından',
    'enerjisini açığa',
    'pozitif enerji',
    'senin için önemli bir',
    'elbette',
    'öncelikle',
    'bu bağlamda',
    'değerlendirildiğinde',
    'potansiyel olarak',
    'seçilir duruyor',
    'bolluk bilinci',
    'sana bıraktığı soru',
    'uydurma bir',
    'iletişim ön plana çıkabilir',
    'may come to the forefront',
    'new developments may',
    'emotional movement may',
    'in this context',
    'of course,',
    'first of all',
    'на первый план',
    'разумеется',
    'в этом контексте',
  ];

  static const certainty = [
    'kesin olacak',
    'kesinlikle olacak',
    'kesinlikle şu olacak',
    'garanti gelecek',
    'şu tarihte',
    'bu kişi kesin',
    'kesin hayatına',
    'hayatına girecek',
    'kesin haber',
    'haber alacaksın',
    'kesin alacaksın',
    'you will definitely',
    'it will definitely',
    'точно будет',
  ];

  static const medical = [
    'hastalığ',
    'şu hastalığın',
    'ömrün uzun',
    'ömrün şu',
    'teşhis',
  ];

  static bool looksRobotic(String text) {
    final lower = text.toLowerCase();
    return robotic.any(lower.contains);
  }

  static bool claimsCertainty(String text) {
    final lower = text.toLowerCase();
    return certainty.any(lower.contains);
  }

  static bool claimsMedical(String text) {
    final lower = text.toLowerCase();
    return medical.any(lower.contains);
  }

  static String scrub(String text) {
    var out = text.trim();
    const swaps = <String, String>{
      'ön plana çıkabilir': 'yeniden görünür olabilir',
      'öne çıkabilir': 'yeniden görünür olabilir',
      'öne çıkan enerji': 'bu portredeki ton',
      'gündeme gelebilir': 'yeniden hatırlanabilir',
      'enerjisi hissedilebilir': 'tonu daha seçilir durur',
      'fırsatlar doğabilir': 'küçük bir kapı aralanabilir',
      'iletişim ön plana': 'yarım kalmış bir konuşma',
      'duygusal gelişmeler olabilir': 'duyguda bir hareketlenme sezilebilir',
      'duygusal bir hareketlilik yaşanabilir':
          'duyguda yumuşak bir kıpırdanma sezilebilir',
      'yeni fırsatlar gündeme gelebilir':
          'bekleyen bir konu yeniden açılabilir',
      'yeni fırsatlar olabilir': 'bekleyen bir konu yeniden açılabilir',
      'may come to the forefront': 'might become visible again',
      'new developments may arise': 'something waiting may reopen',
      'new developments may': 'something waiting may',
      'emotional movement may': 'feeling may stir softly',
      'на первый план': 'снова может стать заметным',
      'kesin haber alacaksın': 'geleneksel yorumda haber gibi okunabilir',
      'kesinlikle şu olacak': 'böyle okunabilir',
      'kesin olacak': 'olası duruyor',
      'haber alacaksın': 'haber gibi okunabilir',
      'kariyer alanınızda değişim': 'iş tarafında bir hareketlenme',
      'bugün harika bir gün': 'bugün biraz daha net bir gün',
      'değişim enerjisi': 'yön değiştirme hissi',
      'dönüşüm enerjisi': 'eski bir kalıbı bırakma hali',
      'kariyer hayatınızda': 'iş tarafında',
      'bugün sizin için': 'bugün',
      'fırsatlar kapıda': 'küçük bir kapı aralanabilir',
      'farkındalık açısından': 'açısından',
      'enerjisini açığa çıkarır': 'tonunu daha seçilir kılar',
      'pozitif enerji': 'daha net bir tempo',
      'senin için önemli bir': 'önemli bir',
      'iç sesine güven': 'durduğun yere bak',
      'seçilir duruyor': 'daha net duruyor',
      'daha seçilir duruyor': 'daha net duruyor',
      'bolluk bilinci': 'tutumlu duruş',
      'sana bıraktığı soru': 'bu faslın bıraktığı yer',
      'uydurma bir düğüm': 'zorlanmış bir düğüm',
      'uydurma bir kapı': 'zorlanmış bir kapı',
    };
    for (final e in swaps.entries) {
      out = out.replaceAll(e.key, e.value);
    }
    return out.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  }

  static String joinSentences(List<String> parts, {int max = 3}) {
    final clean = parts
        .map((p) => _ensurePeriod(_cap(p.trim())))
        .where((p) => p.isNotEmpty)
        .toList();
    if (clean.isEmpty) return '';
    return clean.length <= max ? clean.join(' ') : clean.take(max).join(' ');
  }

  static String _cap(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  static String _ensurePeriod(String text) {
    if (text.isEmpty) return text;
    final last = text[text.length - 1];
    if (last == '.' || last == '!' || last == '?') return text;
    return '$text.';
  }
}
