/// OR-1100 — Mock daily energy repository.
library;

import '../../domain/models/daily_energy.dart';
import '../../domain/repositories/daily_energy_repository.dart';

class MockDailyEnergyRepository implements DailyEnergyRepository {
  @override
  Future<DailyEnergyModel> getToday() async {
    return DailyEnergyModel(
      title: 'Günlük Kozmik Enerji',
      description:
          'Bugün sezgilerin güçleniyor. İç sesine güven ve adımlarını bilinçle at.',
      moodLabel: 'Sezgisel',
      energyLevel: 0.78,
      date: DateTime.now(),
      illustrationAsset: 'lib/assets/images/daily_energy_moon.png',
    );
  }

  @override
  Future<List<DailyEnergyModel>> getRecent({int days = 7}) async {
    final today = await getToday();
    return List.generate(days, (i) {
      return DailyEnergyModel(
        title: today.title,
        description: today.description,
        moodLabel: today.moodLabel,
        energyLevel: (today.energyLevel - i * 0.04).clamp(0.4, 1.0),
        date: today.date.subtract(Duration(days: i)),
        illustrationAsset: today.illustrationAsset,
      );
    });
  }
}
