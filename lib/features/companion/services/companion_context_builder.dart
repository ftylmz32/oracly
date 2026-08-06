/// SPRINT-003 — Builds journey context from intelligence + saved memory.
library;

import '../../../core/intelligence/services/intelligence_layer_service.dart';
import '../../../features/daily_ritual/models/daily_ritual_day.dart';
import '../../../features/daily_ritual/services/daily_ritual_service.dart';
import '../../../../services/memory_service.dart';
import '../models/reflection_context.dart';
import 'companion_memory_service.dart';

class CompanionContextBuilder {
  CompanionContextBuilder({
    required IntelligenceLayerService intelligence,
    CompanionMemoryService? memoryService,
    DailyRitualService? dailyRitual,
  })  : _intelligence = intelligence,
        _memory = memoryService ??
            CompanionMemoryService(MemoryService()),
        _dailyRitual = dailyRitual;

  final IntelligenceLayerService _intelligence;
  final CompanionMemoryService _memory;
  final DailyRitualService? _dailyRitual;

  Future<ReflectionContext> build() async {
    final snapshot = await _intelligence.snapshot();
    final saved = await _memory.savedMemories();
    final userName = await MemoryService().getUserName();
    final ritualDay = _dailyRitual?.loadToday();

    final reflections = snapshot.reflections
        .map((r) => r.text)
        .where((t) => t.trim().isNotEmpty)
        .take(3)
        .toList();

    final themes = <String>[];
    if (snapshot.journey.recurringCards >= 2) {
      themes.add('Tekrarlayan kartlar');
    }
    if (snapshot.counts.readings >= 2) {
      themes.add('Düzenli açılımlar');
    }
    if (snapshot.counts.reflections >= 2) {
      themes.add('Kişisel yansımalar');
    }

    final journalHint = _unfinishedJournalHint(ritualDay);
    final acknowledgment = _proactiveAcknowledgment(
      reflections: reflections,
      themes: themes,
      readingCount: snapshot.counts.readings,
      journalHint: journalHint,
    );

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
      proactiveAcknowledgment: acknowledgment,
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

  String? _proactiveAcknowledgment({
    required List<String> reflections,
    required List<String> themes,
    required int readingCount,
    String? journalHint,
  }) {
    if (journalHint != null) return journalHint;
    if (reflections.isNotEmpty && themes.isNotEmpty) {
      return 'Son yansımalarında ${themes.first.toLowerCase()} teması '
          'belirginleşmiş gibi görünüyor. İstersen oradan devam edebiliriz.';
    }
    if (readingCount >= 2 && reflections.isNotEmpty) {
      return 'Son açılımından bir iz taşıyor olabilirsin. '
          'Konuşmak istersen buradayım.';
    }
    return null;
  }

  String welcomeMessage(ReflectionContext context) {
    final base = context.userName != null && context.userName!.isNotEmpty
        ? 'Merhaba, ${context.userName}.\n'
        : 'Merhaba.\n';

    final intro =
        'Burada acele yok — önce dinlerim, sonra birlikte düşünürüz. '
        'Bugün aklında ne var?';

    if (context.shouldAcknowledgeProactively) {
      return '$base${context.proactiveAcknowledgment}\n\n$intro';
    }
    return '$base$intro';
  }
}
