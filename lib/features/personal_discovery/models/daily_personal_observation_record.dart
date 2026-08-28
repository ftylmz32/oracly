/// Cached daily observation — keyed by date and evidence fingerprint.
library;

class DailyPersonalObservationRecord {
  const DailyPersonalObservationRecord({
    required this.dateKey,
    required this.evidenceFingerprint,
    required this.theme,
    required this.line,
    required this.variant,
  });

  final String dateKey;
  final String evidenceFingerprint;
  final String theme;
  final String line;
  final int variant;

  Map<String, dynamic> toJson() => {
        'dateKey': dateKey,
        'evidenceFingerprint': evidenceFingerprint,
        'theme': theme,
        'line': line,
        'variant': variant,
      };

  factory DailyPersonalObservationRecord.fromJson(Map<String, dynamic> json) {
    return DailyPersonalObservationRecord(
      dateKey: '${json['dateKey']}',
      evidenceFingerprint: '${json['evidenceFingerprint']}',
      theme: '${json['theme']}',
      line: '${json['line']}',
      variant: json['variant'] as int? ?? 0,
    );
  }
}
