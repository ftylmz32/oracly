/// Resolves today's card once — reopen returns the same identity.
library;

import '../../../core/data/datasources/local_storage.dart';
import '../models/card_of_the_day.dart';
import 'card_of_the_day_picker.dart';
import 'card_of_the_day_store.dart';
import 'daily_ritual_service.dart';

class CardOfTheDayService {
  CardOfTheDayService(LocalStorage storage, {DailyRitualService? ritual})
      : _store = CardOfTheDayStore(storage),
        _ritual = ritual ?? DailyRitualService(storage);

  final CardOfTheDayStore _store;
  final DailyRitualService _ritual;

  CardOfTheDay? peekToday([DateTime? day]) => _store.readToday(day);

  /// First open picks and persists; later opens return the same card.
  Future<CardOfTheDay> openToday([DateTime? day]) async {
    final clock = day ?? DateTime.now();
    final existing = _store.readToday(clock);
    if (existing != null) return existing;
    final next = CardOfTheDay(
      day: DateTime(clock.year, clock.month, clock.day),
      ritualId: CardOfTheDayPicker.ritualIdFor(clock),
    );
    await _store.commit(next);
    await _ritual.markCardDrawn(clock);
    return next;
  }
}
