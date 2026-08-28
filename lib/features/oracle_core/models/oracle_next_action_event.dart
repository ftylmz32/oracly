/// Shown / dismissed memory row for NextAction anti-repetition.
library;

class OracleNextActionEvent {
  const OracleNextActionEvent({
    required this.theme,
    required this.feature,
    required this.at,
    required this.kind,
    this.evidenceIds = const [],
  });

  final String theme;
  final String feature;
  final DateTime at;
  final String kind; // shown | dismissed
  final List<String> evidenceIds;

  Map<String, dynamic> toJson() => {
        'theme': theme,
        'feature': feature,
        'at': at.toIso8601String(),
        'kind': kind,
        'evidenceIds': evidenceIds,
      };

  factory OracleNextActionEvent.fromJson(Map<String, dynamic> json) {
    final raw = json['evidenceIds'];
    return OracleNextActionEvent(
      theme: '${json['theme'] ?? ''}',
      feature: '${json['feature'] ?? ''}',
      at: DateTime.tryParse('${json['at'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      kind: '${json['kind'] ?? 'shown'}',
      evidenceIds: raw is List
          ? [for (final e in raw) '$e']
          : const <String>[],
    );
  }
}
