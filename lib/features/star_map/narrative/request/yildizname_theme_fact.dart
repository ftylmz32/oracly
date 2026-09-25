/// Verified discovery theme — label only, max 3 in request.
library;

final class YildiznameThemeFact {
  const YildiznameThemeFact({
    required this.themeRef,
    required this.label,
  });

  final String themeRef;
  final String label;

  Map<String, dynamic> toProviderJson() => {
        'themeRef': themeRef,
        'label': label,
      };
}
