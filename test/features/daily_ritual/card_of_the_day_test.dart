/// Card of the Day — one persisted card per calendar day.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/daily_ritual/copy/card_of_the_day_copy.dart';
import 'package:oracly_new/features/daily_ritual/services/card_of_the_day_picker.dart';
import 'package:oracly_new/features/daily_ritual/services/card_of_the_day_service.dart';
import 'package:oracly_new/features/daily_ritual/services/daily_ritual_reflections.dart';
import 'package:oracly_new/features/daily_ritual/services/daily_ritual_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LocalStorage storage;
  late CardOfTheDayService service;
  final day = DateTime(2026, 8, 20);
  final next = DateTime(2026, 8, 21);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorage(await SharedPreferences.getInstance());
    service = CardOfTheDayService(
      storage,
      ritual: DailyRitualService(storage),
    );
  });

  test('same day always returns the persisted card', () async {
    final first = await service.openToday(day);
    final second = await service.openToday(day);
    expect(second.ritualId, first.ritualId);
    expect(second.dateKey, first.dateKey);
    expect(second.ritualId, CardOfTheDayPicker.ritualIdFor(day));
    expect(DailyRitualService(storage).loadToday(day).cardDrawn, isTrue);
  });

  test('next day selects a new card without redrawing yesterday', () async {
    final first = await service.openToday(day);
    final later = await service.openToday(next);
    expect(later.dateKey, isNot(first.dateKey));
    expect(later.ritualId, CardOfTheDayPicker.ritualIdFor(next));
    expect(service.peekToday(day), isNull);
    expect(service.peekToday(next)?.ritualId, later.ritualId);
  });

  test('picker is stable for a given date', () {
    expect(
      CardOfTheDayPicker.ritualIdFor(day),
      CardOfTheDayPicker.ritualIdFor(DateTime(2026, 8, 20, 23, 59)),
    );
    expect(CardOfTheDayPicker.ritualIdFor(day), inInclusiveRange(0, 77));
  });

  test('copy invites OR without promising the future', () {
    OraclyL10n.bind('tr');
    expect(CardOfTheDayCopy.orOpen, 'OR ile aç');
    expect(CardOfTheDayCopy.honesty.toLowerCase(), contains('yansıma'));
    expect(CardOfTheDayCopy.honesty.toLowerCase(), isNot(contains('kesin')));
    expect(DailyRitualReflections.drawCta(drawn: true), 'Günün kartını aç');
  });
}
