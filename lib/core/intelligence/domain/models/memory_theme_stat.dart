/// One recurring theme — counts only, never a transcript.
library;

class MemoryThemeStat {
  const MemoryThemeStat({
    required this.id,
    required this.label,
    required this.frequency,
    required this.lastSeenAt,
    required this.sourceDiversity,
    this.recencyWeight = 0,
  });

  final String id;
  final String label;
  final int frequency;
  final DateTime lastSeenAt;
  final int sourceDiversity;
  final double recencyWeight;

  bool get isRecent => recencyWeight >= 0.7;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'frequency': frequency,
        'lastSeenAt': lastSeenAt.toIso8601String(),
        'sourceDiversity': sourceDiversity,
        'recencyWeight': recencyWeight,
      };

  factory MemoryThemeStat.fromJson(Map<String, dynamic> json) {
    return MemoryThemeStat(
      id: (json['id'] as String? ?? '').trim(),
      label: (json['label'] as String? ?? '').trim(),
      frequency: json['frequency'] as int? ?? 0,
      lastSeenAt: DateTime.tryParse(json['lastSeenAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      sourceDiversity: json['sourceDiversity'] as int? ?? 0,
      recencyWeight: (json['recencyWeight'] as num?)?.toDouble() ?? 0,
    );
  }
}
