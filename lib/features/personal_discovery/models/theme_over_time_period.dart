/// Archival comparison windows — only real observation spans.
library;

enum ThemeOverTimePeriod {
  days7(7),
  days30(30),
  days90(90);

  const ThemeOverTimePeriod(this.dayCount);

  final int dayCount;
}
