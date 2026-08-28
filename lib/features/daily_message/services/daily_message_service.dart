/// One deterministic local ritual line per calendar day.
library;

import '../../premium/models/personalization_models.dart';
import '../../personal_discovery/models/personal_insight.dart';
import '../models/daily_message.dart';
import '../models/daily_return_action.dart';
import 'daily_return_composer.dart';

export '../models/daily_message.dart';
export '../models/daily_return_action.dart';

abstract final class DailyMessageService {
  DailyMessageService._();

  static DailyMessage forDay({
    required DateTime day,
    String? profileName,
    List<String> themes = const [],
    PersonalInsight? insight,
    String? previousTheme,
    String? previousText,
    DailyReturnAction? previousAction,
    List<String> recentTexts = const [],
    String? sunSign,
    AiPersonality? personality,
    bool hasDiscoveries = false,
  }) {
    final date = DateTime(day.year, day.month, day.day);
    final sign = sunSign?.trim();
    final composed = DailyReturnComposer.compose(
      day: date,
      salt: (profileName ?? '').trim(),
      themes: themes,
      insightTheme: insight?.theme,
      insightExplanation: insight?.explanation,
      previousTheme: previousTheme,
      previousText: previousText,
      recentTexts: recentTexts,
      previousAction: previousAction,
      personality: personality,
      hasDiscoveries: hasDiscoveries,
    );
    return DailyMessage(
      text: composed.text,
      day: date,
      theme: composed.theme,
      action: composed.action,
      sunSign: (sign == null || sign.isEmpty) ? null : sign,
    );
  }
}
