/// OR-1130 — Astrology chart record for API/sync.
library;

class AstrologyRecord {
  const AstrologyRecord({
    required this.id,
    required this.sign,
    required this.horoscope,
    required this.date,
  });

  final String id;
  final String sign;
  final String horoscope;
  final DateTime date;

  Map<String, dynamic> toJson() => {
        'id': id,
        'sign': sign,
        'horoscope': horoscope,
        'date': date.toIso8601String(),
      };

  factory AstrologyRecord.fromJson(Map<String, dynamic> json) {
    return AstrologyRecord(
      id: json['id'] as String,
      sign: json['sign'] as String,
      horoscope: json['horoscope'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }
}
