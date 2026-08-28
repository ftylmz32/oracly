/// Theme-over-time comparisons use only real observation records.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/personal_discovery/models/discovery_observation.dart';
import 'package:oracly_new/features/personal_discovery/models/theme_over_time_period.dart';
import 'package:oracly_new/features/personal_discovery/services/theme_over_time_builder.dart';

DiscoveryObservation _obs(
  String theme,
  DateTime at, {
  String source = 'tarot',
}) =>
    DiscoveryObservation(source: source, theme: theme, observedAt: at);

void main() {
  final now = DateTime(2026, 8, 19, 12);

  test('returns nothing without enough observations', () {
    final results = ThemeOverTimeBuilder.fromObservations(
      [
        _obs('karar verme', now.subtract(const Duration(days: 2))),
        _obs('değişim', now.subtract(const Duration(days: 1))),
      ],
      now: now,
    );
    expect(results, isEmpty);
  });

  test('hides period when halves lack enough data', () {
    final results = ThemeOverTimeBuilder.fromObservations(
      [
        _obs('karar verme', now.subtract(const Duration(days: 6))),
        _obs('karar verme', now.subtract(const Duration(days: 5))),
        _obs('karar verme', now.subtract(const Duration(days: 4))),
        _obs('değişim', now),
      ],
      now: now,
    );
    expect(results.where((c) => c.period == ThemeOverTimePeriod.days7), isEmpty);
  });

  test('surfaces a supported theme shift in the 7-day window', () {
    final results = ThemeOverTimeBuilder.fromObservations(
      [
        _obs('karar verme', now.subtract(const Duration(days: 6)), source: 'tarot'),
        _obs('karar verme', now.subtract(const Duration(days: 5)), source: 'dream'),
        _obs('değişim', now.subtract(const Duration(days: 2)), source: 'coffee'),
        _obs('değişim', now.subtract(const Duration(days: 1)), source: 'tarot'),
      ],
      now: now,
    );
    final week = results.firstWhere((c) => c.period == ThemeOverTimePeriod.days7);
    expect(week.themesDiffer, isTrue);
    expect(week.earlier.theme, 'karar verme');
    expect(week.recent.theme, 'değişim');
  });

  test('stable dominant theme does not invent a shift', () {
    final results = ThemeOverTimeBuilder.fromObservations(
      [
        _obs('karar verme', now.subtract(const Duration(days: 25)), source: 'tarot'),
        _obs('karar verme', now.subtract(const Duration(days: 22)), source: 'dream'),
        _obs('karar verme', now.subtract(const Duration(days: 8)), source: 'coffee'),
        _obs('karar verme', now.subtract(const Duration(days: 2)), source: 'tarot'),
      ],
      now: now,
    );
    final month = results.firstWhere((c) => c.period == ThemeOverTimePeriod.days30);
    expect(month.themesDiffer, isFalse);
    expect(month.earlier.theme, 'karar verme');
    expect(month.recent.theme, 'karar verme');
  });
}
