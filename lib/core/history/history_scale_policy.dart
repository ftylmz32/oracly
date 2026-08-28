/// Long-term history scale — retention + analysis windows (never raw AI dumps).
library;

abstract final class HistoryScalePolicy {
  HistoryScalePolicy._();

  /// Max persisted readings (newest kept).
  static const retentionCap = 1000;

  /// Newest rows used for theme / insight lexicon scans.
  static const themeAnalysisWindow = 200;

  static List<T> newestFirst<T>(List<T> items, int max) {
    if (items.length <= max) return items;
    return items.sublist(0, max);
  }

  static List<T> newestByDate<T>(
    List<T> items,
    DateTime Function(T) at, {
    int max = themeAnalysisWindow,
  }) {
    if (items.length <= max) return items;
    final copy = [...items]..sort((a, b) => at(b).compareTo(at(a)));
    return copy.sublist(0, max);
  }

  static List<String> trimEncodedRetention(List<String> newestFirst) {
    if (newestFirst.length <= retentionCap) return newestFirst;
    return newestFirst.sublist(0, retentionCap);
  }
}
