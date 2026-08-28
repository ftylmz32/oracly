/// Face and back asset paths for the ORACLY 78-card deck.
library;

import 'oracly_tarot_enums.dart';

abstract final class OraclyTarotAssets {
  OraclyTarotAssets._();

  static const cardBack = 'assets/tarot/card_back/oracly_tarot_back_portrait.svg';
  static const cardsRoot = 'assets/tarot/cards';

  static const majorFiles = <String>[
    '00_fool.webp',
    '01_magician.webp',
    '02_high_priestess.webp',
    '03_empress.webp',
    '04_emperor.webp',
    '05_hierophant.webp',
    '06_lovers.webp',
    '07_chariot.webp',
    '08_strength.webp',
    '09_hermit.webp',
    '10_wheel.webp',
    '11_justice.webp',
    '12_hanged_man.webp',
    '13_death.webp',
    '14_temperance.webp',
    '15_devil.webp',
    '16_tower.webp',
    '17_star.webp',
    '18_moon.webp',
    '19_sun.webp',
    '20_judgement.webp',
    '21_world.webp',
  ];

  static const _minorFiles = <int, String>{
    1: '01_ace.webp',
    2: '02_two.webp',
    3: '03_three.webp',
    4: '04_four.webp',
    5: '05_five.webp',
    6: '06_six.webp',
    7: '07_seven.webp',
    8: '08_eight.webp',
    9: '09_nine.webp',
    10: '10_ten.webp',
    11: '11_page.webp',
    12: '12_knight.webp',
    13: '13_queen.webp',
    14: '14_king.webp',
  };

  static String visualFor({
    required OraclyTarotArcana arcana,
    required OraclyTarotSuit suit,
    required int number,
  }) {
    if (arcana == OraclyTarotArcana.major) {
      final i = number.clamp(0, 21);
      return '$cardsRoot/major/${majorFiles[i]}';
    }
    final file = _minorFiles[number] ?? '01_ace.webp';
    return '$cardsRoot/${suit.name}/$file';
  }
}
