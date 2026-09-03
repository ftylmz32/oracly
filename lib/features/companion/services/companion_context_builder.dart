/// Builds journey context from intelligence + saved memory. Never invents.
library;

import '../../../core/domain/repositories/user_repository.dart';
import '../../../core/intelligence/services/intelligence_layer_service.dart';
import '../../../core/intelligence/services/personal_memory_service.dart';
import '../../../features/daily_ritual/models/daily_ritual_day.dart';
import '../../../features/daily_ritual/services/daily_ritual_service.dart';
import '../../../services/memory_service.dart';
import '../copy/companion_copy.dart';
import '../models/reflection_context.dart';
import 'companion_memory_service.dart';

class CompanionContextBuilder {
  CompanionContextBuilder({
    required this.intelligence,
    CompanionMemoryService? memoryService,
    this.personalMemory,
    this.dailyRitual,
    this.users,
    this.observationLine,
  }) : _memory = memoryService ?? CompanionMemoryService(MemoryService());

  final IntelligenceLayerService intelligence;
  final PersonalMemoryService? personalMemory;
  final DailyRitualService? dailyRitual;
  final UserRepository? users;
  final Future<String?> Function()? observationLine;
  final CompanionMemoryService _memory;

  static const _themeLimit = 3;

  Future<ReflectionContext> build() async {
    final snapshot = await intelligence.snapshot();
    final saved = await _memory.savedMemories();
    final userName = await _resolveName();
    final ritualDay = dailyRitual?.loadToday();
    final memoryLine = personalMemory?.observationalLine();
    final observation = await observationLine?.call();

    final reflections = snapshot.reflections
        .map((r) => r.text)
        .where((t) => t.trim().isNotEmpty)
        .take(3)
        .toList();

    final themes = snapshot.journey.insightReport.recurringThemes
        .map((echo) => echo.theme.label.trim())
        .where((label) => label.isNotEmpty)
        .take(_themeLimit)
        .toList();

    final journalHint = _unfinishedJournalHint(ritualDay);
    return ReflectionContext(
      userName: userName,
      savedMemories: saved,
      recentReflectionTexts: reflections,
      recurringThemes: themes,
      readingCount: snapshot.counts.readings,
      dreamCount: snapshot.counts.reflections,
      hasBirthChart: false,
      ritualDaysCount: snapshot.ritualDays.length,
      unfinishedJournalHint: journalHint,
      proactiveAcknowledgment: observation ?? memoryLine,
    );
  }

  String? _unfinishedJournalHint(DailyRitualDay? ritualDay) {
    if (ritualDay == null) return null;
    final thought = ritualDay.personalThought?.trim();
    if (thought != null && thought.isNotEmpty) return null;
    if (ritualDay.reflectionRead || ritualDay.cardDrawn) {
      return 'Bugünkü ritüelinde bir düşünce bırakmadın — '
          'istersen burada tamamlayabiliriz.';
    }
    return null;
  }

  Future<String?> _resolveName() async {
    try {
      final fromProfile = (await users?.getProfile())?.name.trim();
      if (fromProfile != null && fromProfile.isNotEmpty) return fromProfile;
    } catch (_) {}
    return MemoryService().getUserName();
  }

  String welcomeMessage(ReflectionContext context) {
    return CompanionCopy.welcome(name: context.userName);
  }
}
