/// Splits catalogue daily copy for presentation. Never invents natal fields.
library;

import '../../../personal_discovery/copy/personal_theme_copy.dart';
import '../../models/astrology_daily_reading.dart';

abstract final class AstrologyReadingPresentation {
  AstrologyReadingPresentation._();

  static String todayLead(AstrologyDailyReading reading) {
    return AstrologyDailyReading.firstSentence(reading.overall);
  }

  static String generalBody(AstrologyDailyReading reading) {
    final overall = reading.overall.trim();
    final lead = todayLead(reading);
    final rest = overall.startsWith(lead)
        ? overall.substring(lead.length).trim()
        : overall;
    if (rest.isNotEmpty) return rest;
    return reading.personality;
  }

  static String hubNarrative(AstrologyDailyReading reading) {
    return storyBody(reading);
  }

  static String storyBody(AstrologyDailyReading reading) {
    return reading.overall.trim();
  }

  static String laneLine(String source) {
    final text = source.trim();
    if (text.isEmpty || text == PersonalThemeCopy.insufficient) return '';
    return AstrologyDailyReading.firstSentence(text);
  }

  static String innerLane(AstrologyDailyReading reading) {
    final inner = laneLine(reading.innerTheme);
    if (inner.isNotEmpty) return inner;
    return laneLine(
      reading.emotion.trim().isNotEmpty ? reading.emotion : reading.personality,
    );
  }

  /// Full inner body for detail (not first-sentence only).
  static String detailInnerBody(AstrologyDailyReading reading) {
    final raw = reading.innerTheme.trim();
    if (raw.isNotEmpty && raw != PersonalThemeCopy.insufficient) return raw;
    final emotion = reading.emotion.trim();
    if (emotion.isNotEmpty && emotion != PersonalThemeCopy.insufficient) {
      return emotion;
    }
    return reading.personality.trim();
  }

  /// Report spine: theme the eye finds first.
  static String mainTheme(
    AstrologyDailyReading reading, [
    List<String> themeLabels = const [],
  ]) {
    for (final label in themeLabels) {
      final t = label.trim();
      if (t.isNotEmpty && t != PersonalThemeCopy.insufficient) return t;
    }
    final inner = laneLine(reading.innerTheme);
    if (inner.isNotEmpty) return inner;
    return AstrologyDailyReading.firstSentence(reading.personality);
  }

  static String attentionPoint(AstrologyDailyReading reading) {
    final caution = reading.caution.trim();
    if (caution.isNotEmpty && caution != PersonalThemeCopy.insufficient) {
      return caution;
    }
    return AstrologyDailyReading.firstSentence(reading.energy);
  }

  static String nextAction(AstrologyDailyReading reading) {
    final advice = reading.advice.trim();
    if (advice.isNotEmpty && advice != PersonalThemeCopy.insufficient) {
      return advice;
    }
    return reading.opportunity.trim();
  }

  static String detailNarrative(AstrologyDailyReading reading) {
    final parts = <String>[];
    _add(parts, reading.overall);
    _add(parts, reading.love);
    _add(parts, reading.career);
    _add(parts, reading.innerTheme);
    return parts.join('\n\n');
  }

  static void _add(List<String> parts, String source) {
    final text = source.trim();
    if (text.isEmpty || text == PersonalThemeCopy.insufficient) return;
    if (parts.any((p) => p.contains(text))) return;
    parts.add(text);
  }
}
