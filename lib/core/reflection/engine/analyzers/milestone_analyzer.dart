/// RC-010 — Detects factual journey milestones.
library;

import '../../domain/models/journey_milestone.dart';
import '../../domain/models/reflection_input.dart';
import '../reflection_engine_thresholds.dart';

abstract final class MilestoneAnalyzer {
  MilestoneAnalyzer._();

  static const _readingMilestones = <int, String>{
    1: 'İlk açılımın kayda geçti.',
    5: 'Beşinci açılımın arşivde.',
    10: 'On açılımlık bir yolculuk birikti.',
    25: 'Yirmi beş kayıtlı an oluştu.',
  };

  static List<JourneyMilestone> analyze(ReflectionInput input) {
    if (input.readings.isEmpty && input.reflections.isEmpty) {
      return const [];
    }

    final milestones = <JourneyMilestone>[];
    final sortedReadings = [...input.readings]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    if (sortedReadings.isNotEmpty) {
      milestones.add(
        JourneyMilestone(
          id: 'milestone_first_reading',
          kind: JourneyMilestoneKind.firstReading,
          reachedAt: sortedReadings.first.createdAt,
          label: _readingMilestones[1]!,
          detail: sortedReadings.first.cardName,
        ),
      );

      for (final entry in _readingMilestones.entries) {
        if (entry.key == 1 || sortedReadings.length < entry.key) continue;
        milestones.add(
          JourneyMilestone(
            id: 'milestone_reading_${entry.key}',
            kind: JourneyMilestoneKind.readingCount,
            reachedAt: sortedReadings[entry.key - 1].createdAt,
            label: entry.value,
            detail: '${entry.key} açılım',
          ),
        );
      }
    }

    final firstReflection = _firstReflection(input);
    if (firstReflection != null) {
      milestones.add(firstReflection);
    }

    final firstFavorite = _firstFavorite(input);
    if (firstFavorite != null) {
      milestones.add(firstFavorite);
    }

    milestones.addAll(_recurringCardMilestones(input));

    final firstRitualThought = _firstRitualThought(input);
    if (firstRitualThought != null) {
      milestones.add(firstRitualThought);
    }

    milestones.sort((a, b) => a.reachedAt.compareTo(b.reachedAt));
    return milestones;
  }

  static JourneyMilestone? _firstReflection(ReflectionInput input) {
    final reflections = [...input.reflections]
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    if (reflections.isEmpty) return null;
    final first = reflections.first;
    return JourneyMilestone(
      id: 'milestone_first_reflection',
      kind: JourneyMilestoneKind.firstReflection,
      reachedAt: first.recordedAt,
      label: 'İlk kişisel yansıman kayda geçti.',
    );
  }

  static JourneyMilestone? _firstFavorite(ReflectionInput input) {
    if (input.favoriteCards.isEmpty) return null;
    final sorted = [...input.favoriteCards]
      ..sort((a, b) => a.favoritedAt.compareTo(b.favoritedAt));
    final first = sorted.first;
    return JourneyMilestone(
      id: 'milestone_first_favorite',
      kind: JourneyMilestoneKind.firstFavorite,
      reachedAt: first.favoritedAt,
      label: 'İlk favori kartın işaretlendi.',
      detail: first.cardName,
    );
  }

  static List<JourneyMilestone> _recurringCardMilestones(ReflectionInput input) {
    final counts = <String, int>{};
    final firstSeen = <String, DateTime>{};

    for (final reading in input.readings) {
      counts[reading.cardName] = (counts[reading.cardName] ?? 0) + 1;
      firstSeen.putIfAbsent(reading.cardName, () => reading.createdAt);
    }

    return counts.entries
        .where((e) => e.value >= ReflectionEngineThresholds.minCardRecurrence)
        .map(
          (entry) => JourneyMilestone(
            id: 'milestone_recurring_${entry.key.toLowerCase()}',
            kind: JourneyMilestoneKind.recurringCard,
            reachedAt: firstSeen[entry.key]!,
            label: '${entry.key} yolculuğunda tekrar belirdi.',
            detail: '${entry.value} kez',
          ),
        )
        .toList();
  }

  static JourneyMilestone? _firstRitualThought(ReflectionInput input) {
    final days = input.ritualDays
        .where(
          (day) =>
              day.personalThought != null &&
              day.personalThought!.trim().isNotEmpty,
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (days.isEmpty) return null;
    return JourneyMilestone(
      id: 'milestone_first_ritual_thought',
      kind: JourneyMilestoneKind.firstRitualThought,
      reachedAt: days.first.date,
      label: 'İlk günlük ritüel düşüncen kaydedildi.',
    );
  }
}
