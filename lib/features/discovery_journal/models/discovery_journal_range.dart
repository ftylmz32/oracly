/// Time window over real journal dates — never invents missing days.
library;

enum DiscoveryJournalRange {
  last7,
  last30,
  last90,
  all;

  DateTime? startOf(DateTime now) {
    return switch (this) {
      last7 => now.subtract(const Duration(days: 7)),
      last30 => now.subtract(const Duration(days: 30)),
      last90 => now.subtract(const Duration(days: 90)),
      all => null,
    };
  }
}
