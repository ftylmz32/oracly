/// OR-050 — Daily energy reading provider.
library;

import '../../../core/l10n/oracly_format.dart';
import '../../../core/theme/app_colors.dart';
import '../models/daily_energy_reading.dart';

/// Legacy mock energy reading — not used by live Home or Universe Map.
abstract final class DailyEnergyService {
  DailyEnergyService._();

  static DailyEnergyReading readingFor({String? summaryOverride}) {
    return DailyEnergyReading(
      summary: summaryOverride ??
          'Bugün sezgin biraz daha net. Acele etmeden tek bir adıma bak.',
      love: 'Küçük ve gerçek bir cümle, belirsiz bekleyişten daha güçlü durur.',
      career: 'Odak daraltmak ilerlemeyi hızlandırır. Tempo tut, dağılma.',
      money: 'Harcama kararında acele yok. Net ihtiyaç ile istek arasını ayır.',
      mood: 'Kısa bir nefes veya kısa yürüyüş yeter. Büyük ritüel şart değil.',
      luckyNumber: 7,
      luckyColor: 'Altın Mor',
      luckyColorHex: AppColors.purpleLight,
      luckyCrystal: 'Ametist',
      cosmicMessage:
          'Bugün cevap dışarıda bağırarak gelmeyebilir. Durduğun yere bakmak yeter.',
      aiInterpretation:
          'Bugün sezgi ve duygu tarafı biraz daha önde. İlişkide netlik, '
          'işte tek tamamlanan iş daha sağlam durur. Taş veya renk şart değil.',
      moonPhaseLabel: 'Büyüyen Ay',
      dateLabel: _todayLabel(),
    );
  }

  static String _todayLabel() => OraclyFormat.date(DateTime.now());
}
