/// Strips cookie, bureaucratic, and implementation language.
library;

import '../copy/fortune_voice.dart';

abstract final class HumanReaderGuard {
  HumanReaderGuard._();

  static const generic = [
    'öne çıkıyor',
    'öne çıkmak',
    'alan açıyor',
    'alan aç',
    'hareketlilik',
    'ön plana',
    'fırsatlar doğ',
    'güzel gelişmeler',
    'yakında güzel',
    'önem arz',
    'bu durum, birey',
    'değerlendirildiğinde',
    'yüzeye çıkabilir',
    'zayıflık değil',
    'duyguda doğrudan ol',
    'öndə çıxmaq',
  ];

  static const bureaucratic = [
    'önem arz etmektedir',
    'söz konusu durum',
    'bu bağlamda',
    'bireyin',
    'potansiyel olarak',
    'gündeme gelebilir',
  ];

  static const implementation = [
    'elimde yalnızca',
    'yalnızca bu burç',
    'tam harita değil',
    'gökyüzü kataloğu',
    'uzun hatta',
    'doğum tarihi yoksa',
    'gökyüzünü uydurmam',
    'tam gökyüzü hesabı',
    'spekülasyonla',
    'keşifler birikmeden burayı doldurmam',
    'boşluğu sahte',
    'sistem tespit',
    'yapay zeka düşün',
    'model sınır',
    'model detected',
    'this is not a complete chart',
    'elimde yalnızca sun',
    'keşif biriktirmemiz',
    'keşif geçmişin oluşmadı',
    'katalog terim',
    'uydurma bir anı değil',
    'görmediğim bir iz eklemiyorum',
    'tarih yok',
    'kehanet değil',
    'okumanın özeti',
    'sembolik mesaj:',
    'varış kehaneti',
    'elimde bugünün enerjisi',
    'ay, yükselen',
    'gündüz ertelediğin',
  ];

  static String scrub(String text) {
    var out = FortuneVoice.scrub(text);
    const swaps = <String, String>{
      'alan açıyor': 'yer bırakıyor',
      'alan aç': 'yer bırak',
      'hareketlilik': 'kıpırdanma',
      'yüzeye çıkabilir': 'yeniden hatırlanabilir',
      'önem arz etmektedir': 'asıl duran şey bu',
      'söz konusu durum': 'burada duran şey',
      'bu bağlamda': '',
      'potansiyel olarak': '',
      'gündeme gelebilir': 'yeniden hatırlanabilir',
      'farkındalık açısından': 'açısından',
      'farkındalığı destekler': 'netleştirmeye yardım eder',
      'seçilir duruyor': 'daha net duruyor',
      'daha seçilir': 'daha net',
      'bolluk bilinci': 'tutumlu duruş',
      'katalog cümlesinden': 'tek bir cümleden',
      'sana bıraktığı soru': 'bu faslın bıraktığı yer',
      'uydurmuyorum': 'zorlamıyorum',
    };
    for (final e in swaps.entries) {
      out = out.replaceAll(e.key, e.value);
    }
    return out.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  }

  static bool looksGeneric(String text) {
    final lower = text.toLowerCase();
    if (FortuneVoice.looksRobotic(text) || FortuneVoice.claimsCertainty(text)) {
      return true;
    }
    if (generic.any(lower.contains) || bureaucratic.any(lower.contains)) {
      return true;
    }
    if (implementation.any(lower.contains)) return true;
    return false;
  }
}
