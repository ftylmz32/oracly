/// Plain Turkish glosses for card names shown in readings.
library;

import '../../../../core/l10n/l10n.dart';

/// Data catalog — short meanings so "5 Tılsım" is never left unexplained.
abstract final class TarotCardGloss {
  TarotCardGloss._();

  static String named(String cardName, int id) {
    if (OraclyL10n.code != 'tr') return cardName;
    final gloss = _byId[id];
    if (gloss == null || gloss.isEmpty) return cardName;
    final lower = cardName.toLowerCase();
    if (lower.contains(gloss.toLowerCase())) return cardName;
    return '$cardName ($gloss)';
  }

  static const _byId = <int, String>{
    0: 'yeni başlangıç',
    1: 'irade ve beceri',
    2: 'sezgi ve iç bilgelik',
    3: 'bereket ve yaratım',
    4: 'düzen ve otorite',
    5: 'inanç ve rehberlik',
    6: 'kalp seçimi',
    7: 'zafer ve ilerleme',
    8: 'iç güç',
    9: 'içe dönüş',
    10: 'değişim çarkı',
    11: 'denge ve adalet',
    12: 'teslimiyet',
    13: 'bitiş ve dönüşüm',
    14: 'ölçü ve denge',
    15: 'bağ ve gölge',
    16: 'yıkım ve uyanış',
    17: 'umut ve şifa',
    18: 'belirsizlik ve sezgi',
    19: 'netlik ve neşe',
    20: 'hesap ve uyanış',
    21: 'tamamlanma',
    // Cups 22–35
    22: 'yeni duygusal akış',
    23: 'ortaklık',
    24: 'kutlama ve bağ',
    25: 'durgunluk',
    26: 'hayal kırıklığı',
    27: 'nostalji',
    28: 'seçenek ve hayal',
    29: 'geride bırakma',
    30: 'doyum',
    31: 'duygusal bolluk',
    32: 'haber ve davet',
    33: 'romantik teklif',
    34: 'olgun duygu',
    35: 'şefkatli bağ',
    // Pentacles 36–49
    36: 'maddi fırsat',
    37: 'denge ve değiş tokuş',
    38: 'emek ve ustalık',
    39: 'tutma ve güvenlik',
    40: 'yalnızlık ve maddi sıkışıklık',
    41: 'cömertlik ve destek',
    42: 'sabırlı yatırım',
    43: 'ustalık ve emek',
    44: 'refah ve bağımsızlık',
    45: 'kalıcı başarı',
    46: 'öğrenme ve pratik',
    47: 'güvenilir teklif',
    48: 'maddi otorite',
    49: 'bolluk ve istikrar',
    // Swords 50–63
    50: 'net fikir',
    51: 'kararsızlık',
    52: 'kalp kırıklığı',
    53: 'dinlenme ihtiyacı',
    54: 'çatışma ve yenilgi',
    55: 'geçiş ve ayrılık',
    56: 'hırsız strateji',
    57: 'kısıtlanma',
    58: 'kaygı',
    59: 'biten bir dönem',
    60: 'keskin zihin',
    61: 'hızlı hamle',
    62: 'adaletli karar',
    63: 'net otorite',
    // Wands 64–77
    64: 'ilham kıvılcımı',
    65: 'plan ve ufuk',
    66: 'genişleme',
    67: 'kutlama ve yuva',
    68: 'rekabet',
    69: 'zafer',
    70: 'savunma',
    71: 'acele ve hareket',
    72: 'dayanıklılık',
    73: 'yük ve sorumluluk',
    74: 'haber ve keşif',
    75: 'tutkulu teklif',
    76: 'girişimci lider',
    77: 'özgüvenli yaratım',
  };
}
