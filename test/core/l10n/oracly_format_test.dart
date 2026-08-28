/// Locale-aware date / time / number formatting for TR · EN · RU.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/l10n/oracly_format.dart';
import 'package:oracly_new/features/birth_chart/data/birth_chart_cities.dart';
import 'package:oracly_new/features/gems/data/gem_display.dart';

void main() {
  setUpAll(() async {
    await OraclyFormat.ensureInitialized();
  });

  final day = DateTime(2026, 8, 13, 15, 30);

  test('TR dates, times, gems, cities use Turkish forms', () {
    OraclyL10n.bind('tr');
    expect(OraclyFormat.date(day), contains('Ağustos'));
    expect(OraclyFormat.date(day), isNot(contains('August')));
    expect(OraclyFormat.time(day), '15:30');
    expect(OraclyFormat.relativeDay(day, now: DateTime(2026, 8, 13)), 'Bugün');
    expect(OraclyFormat.relativeDay(day, now: DateTime(2026, 8, 14)), 'Dün');
    expect(GemDisplay.format(1250), '1.250');
    expect(OraclyFormat.cardNumber(14), '14');
    final istanbul = BirthChartCities.byName('istanbul')!;
    expect(istanbul.label(), 'İstanbul');
  });

  test('EN dates, times, gems, cities use English forms', () {
    OraclyL10n.bind('en');
    expect(OraclyFormat.date(day), contains('August'));
    expect(OraclyFormat.date(day), isNot(contains('Ağustos')));
    expect(OraclyFormat.time(day).toLowerCase(), contains('3:30'));
    expect(OraclyFormat.relativeDay(day, now: DateTime(2026, 8, 13)), 'Today');
    expect(OraclyFormat.relativeDay(day, now: DateTime(2026, 8, 14)), 'Yesterday');
    expect(GemDisplay.format(1250), '1,250');
    final london = BirthChartCities.byName('london')!;
    expect(london.label(), 'London');
    expect(london.label(), isNot(contains('Londra')));
    final istanbul = BirthChartCities.byName('istanbul')!;
    expect(istanbul.label(), 'Istanbul');
  });

  test('RU dates, times, gems, cities use Russian forms', () {
    OraclyL10n.bind('ru');
    final label = OraclyFormat.date(day).toLowerCase();
    expect(label, contains('август'));
    expect(label, isNot(contains('ağustos')));
    expect(label, isNot(contains('august')));
    expect(OraclyFormat.time(day), '15:30');
    expect(OraclyFormat.relativeDay(day, now: DateTime(2026, 8, 13)), 'Сегодня');
    expect(OraclyFormat.relativeDay(day, now: DateTime(2026, 8, 14)), 'Вчера');
    final gems = GemDisplay.format(1250);
    expect(gems.replaceAll(RegExp(r'\s'), ''), '1250');
    expect(gems, isNot(contains('.')));
    expect(gems, isNot(contains(',')));
    final london = BirthChartCities.byName('london')!;
    expect(london.label(), 'Лондон');
    final istanbul = BirthChartCities.byName('istanbul')!;
    expect(istanbul.label(), 'Стамбул');
  });
}
