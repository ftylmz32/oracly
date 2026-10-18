/// Turkish daily astrology pools: varied, sign-specific, never a fake sky.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/astrology/data/astrology_day_pool_tr.dart';
import 'package:oracly_new/features/astrology/services/astrology_daily_reading_service.dart';
import 'package:oracly_new/features/content/astrology/data/astrology_content_catalogue.dart';

const _sky = ['ay burcu', 'yükselen', 'evler', 'gezegen', 'natal', 'transit'];

const _lecture = [
  'burcu olarak',
  'ateş burcu',
  'su burcu',
  'toprak burcu',
  'hava burcu',
  'burçlarının',
  'yavaş açılır',
  'her zamankinden',
  'kabuğuna',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => OraclyL10n.bind('tr'));

  test('every sign has a full, unique pool with no invented sky terms', () {
    expect(kAstrologyDayPoolTr.keys, hasLength(12));
    final all = <String>[];
    for (final pool in kAstrologyDayPoolTr.values) {
      expect(pool.overall.length, greaterThanOrEqualTo(8));
      for (final lane in [pool.love, pool.career, pool.caution, pool.advice]) {
        expect(lane.length, greaterThanOrEqualTo(3));
      }
      all
        ..addAll(pool.overall)
        ..addAll(pool.love)
        ..addAll(pool.career)
        ..addAll(pool.money)
        ..addAll(pool.energy)
        ..addAll(pool.emotion)
        ..addAll(pool.advice)
        ..addAll(pool.opportunity)
        ..addAll(pool.caution);
    }
    expect(all.toSet(), hasLength(all.length));
    for (final line in all) {
      final lower = line.toLowerCase();
      for (final word in _sky) {
        expect(lower, isNot(contains(word)), reason: line);
      }
      for (final word in _lecture) {
        expect(lower, isNot(contains(word)), reason: line);
      }
    }
    for (final pool in kAstrologyDayPoolTr.values) {
      for (final line in pool.overall) {
        expect(line.length, greaterThanOrEqualTo(150), reason: line);
        expect('.'.allMatches(line).length, greaterThanOrEqualTo(2), reason: line);
      }
      for (final line in [...pool.love, ...pool.career]) {
        expect(line.length, greaterThanOrEqualTo(90), reason: line);
      }
    }
  });

  test('no visible lane repeats on consecutive days', () {
    for (final sign in AstrologyContentCatalogue.signs) {
      for (var i = 0; i < 20; i++) {
        final a = AstrologyDailyReadingService.build(
          sign,
          now: DateTime(2026, 10, 1).add(Duration(days: i)),
        );
        final b = AstrologyDailyReadingService.build(
          sign,
          now: DateTime(2026, 10, 1).add(Duration(days: i + 1)),
        );
        expect(a.overall, isNot(b.overall));
        expect(a.love, isNot(b.love));
        expect(a.career, isNot(b.career));
        expect(a.caution, isNot(b.caution));
        expect(a.advice, isNot(b.advice));
      }
    }
  });

  test('a week of overall readings never repeats for a sign', () {
    for (final sign in AstrologyContentCatalogue.signs) {
      final week = {
        for (var i = 0; i < 8; i++)
          AstrologyDailyReadingService.build(
            sign,
            now: DateTime(2026, 10, 1).add(Duration(days: i)),
          ).overall,
      };
      expect(week, hasLength(8), reason: sign.id);
    }
  });
}
