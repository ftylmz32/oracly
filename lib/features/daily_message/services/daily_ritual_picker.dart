/// Deterministic pick that skips recent wording and sentence shape.
library;

import '../data/daily_message_catalogue.dart';
import '../../premium/models/personalization_models.dart';

abstract final class DailyRitualPicker {
  DailyRitualPicker._();

  static String line({
    required List<String> pool,
    required String seed,
    List<String> recent = const [],
    AiPersonality? voice,
  }) {
    if (pool.isEmpty) return '';
    if (pool.length == 1) return pool.first;
    final tuned = _tune(pool, voice);
    final avoidExact = {for (final t in recent) t.trim()}.where((t) => t.isNotEmpty);
    final avoidShape = {
      for (final t in recent) DailyMessageCatalogue.structureOf(t),
    };
    final start = seed.hashCode.abs() % tuned.length;
    String? shapeFallback;
    String? anyFallback;
    for (var i = 0; i < tuned.length; i++) {
      final candidate = tuned[(start + i) % tuned.length];
      if (avoidExact.contains(candidate)) continue;
      anyFallback ??= candidate;
      if (avoidShape.contains(DailyMessageCatalogue.structureOf(candidate))) {
        shapeFallback ??= candidate;
        continue;
      }
      return candidate;
    }
    return shapeFallback ?? anyFallback ?? tuned[start];
  }

  static List<String> _tune(List<String> pool, AiPersonality? voice) {
    if (voice == null || pool.length < 3) return pool;
    return switch (voice) {
      AiPersonality.direct => pool.take(2).toList(),
      AiPersonality.gentle => pool.skip(1).take(2).toList(),
      AiPersonality.poetic => pool.length > 2 ? pool.sublist(2) : pool,
      AiPersonality.mystical => [pool.first, pool.last],
    };
  }
}
