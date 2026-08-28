/// One theme sighting from a real discovery record.
library;

class DiscoveryObservation {
  const DiscoveryObservation({
    required this.source,
    required this.theme,
    required this.observedAt,
  });

  final String source;
  final String theme;
  final DateTime observedAt;
}
