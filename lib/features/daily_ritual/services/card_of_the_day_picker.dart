/// Stable once-per-day card id from the calendar date.
library;

abstract final class CardOfTheDayPicker {
  CardOfTheDayPicker._();

  static int ritualIdFor(DateTime day) {
    final key =
        '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    var hash = 2166136261;
    for (final unit in key.codeUnits) {
      hash ^= unit;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return hash % 78;
  }
}
