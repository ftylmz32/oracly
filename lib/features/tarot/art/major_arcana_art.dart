/// Major Arcana artwork paths + Flutter chrome labels.
library;

abstract final class MajorArcanaArt {
  MajorArcanaArt._();

  static const root = 'lib/assets/images/tarot/major_arcana';
  static const cardBack = 'lib/assets/images/tarot/tarot_card_back.webp';

  static const romans = <String>[
    '0',
    'I',
    'II',
    'III',
    'IV',
    'V',
    'VI',
    'VII',
    'VIII',
    'IX',
    'X',
    'XI',
    'XII',
    'XIII',
    'XIV',
    'XV',
    'XVI',
    'XVII',
    'XVIII',
    'XIX',
    'XX',
    'XXI',
  ];

  static const titles = <String>[
    'DELİ',
    'BÜYÜCÜ',
    'BAŞRAHİBE',
    'İMPARATORİÇE',
    'İMPARATOR',
    'AZİZ',
    'ÂŞIKLAR',
    'SAVAŞ ARABASI',
    'GÜÇ',
    'ERMİŞ',
    'KADER ÇARKI',
    'ADALET',
    'ASILAN ADAM',
    'ÖLÜM',
    'DENGE',
    'ŞEYTAN',
    'KULE',
    'YILDIZ',
    'AY',
    'GÜNEŞ',
    'YARGI',
    'DÜNYA',
  ];

  static const files = <String>[
    '00_deli.webp',
    '01_buyucu.webp',
    '02_basrahibe.webp',
    '03_imparatorice.webp',
    '04_imparator.webp',
    '05_aziz.webp',
    '06_asiklar.webp',
    '07_savas_arabasi.webp',
    '08_guc.webp',
    '09_ermis.webp',
    '10_kader_carki.webp',
    '11_adalet.webp',
    '12_asilan_adam.webp',
    '13_olum.webp',
    '14_denge.webp',
    '15_seytan.webp',
    '16_kule.webp',
    '17_yildiz.webp',
    '18_ay.webp',
    '19_gunes.webp',
    '20_yargi.webp',
    '21_dunya.webp',
  ];

  static String assetFor(int id) => '$root/${files[id.clamp(0, 21)]}';

  static String romanFor(int id) => romans[id.clamp(0, 21)];

  static String titleFor(int id) => titles[id.clamp(0, 21)];

  static bool isMajorAsset(String path) =>
      path.contains('tarot/major_arcana/') ||
      path.contains('cards/tarot/major/');

  static int? idFromAsset(String path) {
    final name = path.split('/').last.toLowerCase();
    for (var i = 0; i < files.length; i++) {
      if (name == files[i].toLowerCase()) return i;
    }
    final digits = RegExp(r'^(\d{2})').firstMatch(name);
    if (digits == null) return null;
    final id = int.tryParse(digits.group(1)!);
    if (id == null || id < 0 || id > 21) return null;
    return id;
  }
}
