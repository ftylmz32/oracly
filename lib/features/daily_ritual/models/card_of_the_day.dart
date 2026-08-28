/// One calendar day's locked tarot card — never regenerates mid-day.
library;

class CardOfTheDay {
  const CardOfTheDay({
    required this.day,
    required this.ritualId,
    this.reversed = false,
  });

  final DateTime day;
  final int ritualId;
  final bool reversed;

  String get dateKey =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
        'dateKey': dateKey,
        'ritualId': ritualId,
        'reversed': reversed,
      };

  factory CardOfTheDay.fromJson(Map<String, dynamic> json) {
    final raw = '${json['dateKey'] ?? ''}';
    final parts = raw.split('-');
    final day = parts.length == 3
        ? DateTime(
            int.tryParse(parts[0]) ?? 2026,
            int.tryParse(parts[1]) ?? 1,
            int.tryParse(parts[2]) ?? 1,
          )
        : DateTime(2026, 1, 1);
    return CardOfTheDay(
      day: day,
      ritualId: (json['ritualId'] as num?)?.toInt() ?? 0,
      reversed: json['reversed'] as bool? ?? false,
    );
  }
}
