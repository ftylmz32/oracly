/// Provider-safe element / modality balance facts from Phase 4 evidence.
library;

final class YildiznameBalanceFact {
  const YildiznameBalanceFact({
    required this.factRef,
    required this.kind,
    required this.counts,
    this.dominant,
  });

  final String factRef;
  final String kind;
  final Map<String, int> counts;
  final String? dominant;

  Map<String, dynamic> toProviderJson() => {
        'factRef': factRef,
        'kind': kind,
        'counts': Map<String, int>.from(counts),
        if (dominant != null) 'dominant': dominant,
      };
}
