/// OR-1130 — Astrology repository interface.
library;

import '../models/astrology_record.dart';

abstract class AstrologyRepository {
  Future<AstrologyRecord?> getDailyHoroscope(String sign);
  Future<List<AstrologyRecord>> getHistory();
  Future<void> save(AstrologyRecord record);
  Future<void> sync();
}
