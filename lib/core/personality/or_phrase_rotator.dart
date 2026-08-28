/// EPIC-015 — Non-repetitive phrase rotation for OR voice lines.
library;

import 'dart:math';

abstract final class OrPhraseRotator {
  OrPhraseRotator._();

  static String pick({
    required List<String> pool,
    required String seed,
    String? avoid,
  }) {
    if (pool.isEmpty) return '';
    if (pool.length == 1) return pool.first;

    final hash = seed.hashCode;
    var index = hash.abs() % pool.length;
    var candidate = pool[index];

    if (avoid != null && pool.length > 1 && candidate == avoid) {
      index = (index + 1 + (hash >> 3).abs()) % pool.length;
      candidate = pool[index];
    }
    return candidate;
  }

  static String daily({
    required List<String> pool,
    required DateTime day,
    String salt = '',
  }) {
    final seed = '${day.year}-${day.month}-${day.day}-$salt';
    return pick(pool: pool, seed: seed);
  }

  static String session({
    required List<String> pool,
    required DateTime moment,
    String salt = '',
  }) {
    final seed =
        '${moment.year}-${moment.month}-${moment.day}-${moment.hour}-$salt';
    return pick(pool: pool, seed: seed);
  }

  static double jitter(Random rng) => 0.96 + rng.nextDouble() * 0.08;
}
