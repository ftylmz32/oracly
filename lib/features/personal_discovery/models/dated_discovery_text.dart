/// Dated discovery text used only while building the profile.
library;

class DatedDiscoveryText {
  const DatedDiscoveryText({
    required this.source,
    required this.text,
    required this.at,
  });

  final String source;
  final String text;
  final DateTime at;
}
