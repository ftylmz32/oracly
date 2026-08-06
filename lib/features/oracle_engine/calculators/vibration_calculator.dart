/// OR-1140 — Daily vibration score calculator.
library;

abstract class VibrationCalculator {
  double scoreFor(DateTime date, {Map<String, dynamic>? inputs});
}

class DateVibrationCalculator implements VibrationCalculator {
  @override
  double scoreFor(DateTime date, {Map<String, dynamic>? inputs}) {
    final seed = date.year + date.month + date.day;
    return (seed % 100) / 100.0;
  }
}
