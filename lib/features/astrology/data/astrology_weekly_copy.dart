/// Sign-aware weekly overview — catalogue text, not ephemeris.
library;

import '../../content/astrology/models/astrology_content.dart';

class AstrologyWeekDay {
  const AstrologyWeekDay({required this.label, required this.text});

  final String label;
  final String text;
}

abstract final class AstrologyWeeklyCopy {
  AstrologyWeeklyCopy._();

  static const _days = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];

  static List<AstrologyWeekDay> week(
    ZodiacSignContent sign, {
    DateTime? now,
  }) {
    final seed = (now ?? DateTime.now()).weekday - 1;
    final lines = _lines(sign);
    return [
      for (var i = 0; i < 7; i++)
        AstrologyWeekDay(
          label: _days[i],
          text: lines[(i + seed) % lines.length],
        ),
    ];
  }

  static List<String> _lines(ZodiacSignContent sign) {
    final n = sign.nameTr;
    return switch (sign.element) {
      ZodiacElement.fire => [
          '$n, haftaya cesaretle gir. Tek görünür hedef seç.',
          '$n, tempo yüksek. Acele söz yerine net bir adım.',
          '$n, yaratım kazandırır. Yarım alkış bekleme.',
          '$n, yönünü kilitle. Dağınık savaşma.',
          '$n, görünür bir teslim seni ilerletir.',
          '$n, iç ateşi dinlendir. Kısa bir durak yeter.',
          '$n, haftayı sade kapat. Yeni cephe açma.',
        ],
      ZodiacElement.earth => [
          '$n, düzenle başla. Eldeki sistemi sağlamlaştır.',
          '$n, emek görünür olur. Kaliteye yatırım yap.',
          '$n, ritmini koru. Ani sapma yorar.',
          '$n, bir işi iyi bitir. Beşi yarım bırakma.',
          '$n, kaynakları toparla. Büyük riski ertele.',
          '$n, beden ve yuva önemli. Yavaşlamak köklenmektir.',
          '$n, haftayı sadeleştir. Fazlalığı çıkar.',
        ],
      ZodiacElement.air => [
          '$n, zihin hızlı. Sözün net olsun.',
          '$n, bir konuyu derinleştir. Onunu yüzeyden geçme.',
          '$n, sohbet bağ kurar. Sözü yarım bırakma.',
          '$n, bir tercihi kapat. İkisini taşıma.',
          '$n, fikri paylaş. İçinde kilitleme.',
          '$n, nefes al. Her mesaja yetişme.',
          '$n, haftayı bir cümleyle özetle.',
        ],
      ZodiacElement.water => [
          '$n, sezgi güçlü. İç sesini yok sayma.',
          '$n, yakın çevreni toparlamak dengeler.',
          '$n, ihtiyacını sakin cümleyle söyle.',
          '$n, sınır koymak soğukluk değildir.',
          '$n, şefkati kendine de göster.',
          '$n, sisin içinde bir gerçeği tut.',
          '$n, haftayı yumuşak ama net kapat.',
        ],
    };
  }
}
