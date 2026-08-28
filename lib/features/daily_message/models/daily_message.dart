/// One calendar-day return snapshot — never a prediction.
library;

import '../../../core/l10n/oracly_format.dart';
import 'daily_return_action.dart';

class DailyMessage {
  const DailyMessage({
    required this.text,
    required this.day,
    this.theme,
    this.action = DailyReturnAction.talkToOr,
    this.sunSign,
  });

  final String text;
  final DateTime day;
  final String? theme;
  final DailyReturnAction action;
  final String? sunSign;

  String get dateKey =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  String get dateLabel => OraclyFormat.date(day);

  String get dateStamp {
    final sign = sunSign?.trim();
    if (sign == null || sign.isEmpty) return dateLabel;
    return '$dateLabel · $sign';
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'day': dateKey,
        if (theme != null) 'theme': theme,
        'action': action.name,
        if (sunSign != null) 'sunSign': sunSign,
      };

  factory DailyMessage.fromJson(Map<String, dynamic> json) {
    final raw = '${json['day'] ?? ''}';
    final parts = raw.split('-');
    final day = parts.length == 3
        ? DateTime(
            int.tryParse(parts[0]) ?? 2026,
            int.tryParse(parts[1]) ?? 1,
            int.tryParse(parts[2]) ?? 1,
          )
        : DateTime(2026, 1, 1);
    return DailyMessage(
      text: '${json['text'] ?? ''}',
      day: day,
      theme: json['theme'] as String?,
      action: DailyReturnAction.fromName(json['action'] as String?),
      sunSign: json['sunSign'] as String?,
    );
  }
}
