/// OR-050 — Daily energy reading provider.
library;

import '../../../core/theme/app_colors.dart';
import '../models/daily_energy_reading.dart';

/// Resolves today's energy reading — mock data for OR-050.
abstract final class DailyEnergyService {
  DailyEnergyService._();

  static DailyEnergyReading readingFor({String? summaryOverride}) {
    return DailyEnergyReading(
      summary: summaryOverride ??
          'Bugün sezgilerin güçleniyor. İç sesine güven ve adımlarını bilinçle at.',
      love: 'Kalbin açık ve alıcı. Küçük jestler büyük anlamlar taşıyabilir.',
      career: 'Odaklanmış enerji kariyerinde net ilerleme getiriyor. Sabırlı ol.',
      money: 'Finansal sezgilerin keskin. Harcamalarında dengeyi koru.',
      mood: 'İç huzurun yükseliyor. Meditasyon ve nefes seni dengeye taşır.',
      luckyNumber: 7,
      luckyColor: 'Altın Mor',
      luckyColorHex: AppColors.purpleLight,
      luckyCrystal: 'Ametist',
      cosmicMessage:
          'Evren bugün seninle fısıldaşıyor. Dinle, çünkü cevaplar sessizlikte saklı.',
      aiInterpretation:
          'Bugünkü enerji profilin sezgisel farkındalığı ve duygusal derinliği '
          'vurguluyor. İlişkilerde empati güçlü; kariyerde stratejik adımlar '
          'destekleniyor. Ametist taşı ve altın-mor tonlar enerjini dengeleyecek.',
      moonPhaseLabel: 'Büyüyen Ay',
      dateLabel: _todayLabel(),
    );
  }

  static String _todayLabel() {
    final now = DateTime.now();
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }
}
