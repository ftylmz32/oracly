/// OR-1100 — Daily energy repository interface.
library;

import '../models/daily_energy.dart';

abstract class DailyEnergyRepository {
  Future<DailyEnergyModel> getToday();
  Future<List<DailyEnergyModel>> getRecent({int days = 7});
}
