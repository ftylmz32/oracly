/// Related theme labels — only used when both exist in real data.
library;

abstract final class ThemeAlternatives {
  ThemeAlternatives._();

  static const map = <String, List<String>>{
    'aşk': ['iletişim', 'sınırlar', 'özgüven', 'karar verme'],
    'ilişki': ['iletişim', 'sınırlar', 'özgüven', 'karar verme'],
    'kariyer': ['karar verme', 'sınırlar', 'özgüven'],
    'iletişim': ['sınırlar', 'karar verme', 'özgüven'],
  };

  static List<String> of(String theme) => map[theme] ?? const [];
}
