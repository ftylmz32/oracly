/// Astrology V1 — saved sign, weekly copy, burç vs chart distinction.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/astrology/data/astrology_preferences_store.dart';
import 'package:oracly_new/features/astrology/data/astrology_weekly_copy.dart';
import 'package:oracly_new/features/astrology/presentation/reference/astrology_reference_kind_note.dart';
import 'package:oracly_new/features/astrology/services/astrology_sign_resolver.dart';
import 'package:oracly_new/features/content/astrology/data/astrology_content_catalogue.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('selected zodiac persists across store instances', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final first = AstrologyPreferencesStore(storage);
    await first.setSelectedSignId('leo');

    final second = AstrologyPreferencesStore(
      LocalStorage(await SharedPreferences.getInstance()),
    );
    expect(second.selectedSignId, 'leo');

    final resolver = AstrologySignResolver(preferences: second);
    expect(await resolver.resolve(), 'leo');
  });

  test('resolver falls back to aries without saved sign or chart', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final resolver = AstrologySignResolver(
      preferences: AstrologyPreferencesStore(storage),
    );
    expect(await resolver.resolve(), AstrologySignResolver.fallbackId);
  });

  test('resolver keeps saved sign instead of fallback', () async {
    SharedPreferences.setMockInitialValues({
      AstrologyPreferencesStore.signKey: 'pisces',
    });
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final resolver = AstrologySignResolver(
      preferences: AstrologyPreferencesStore(storage),
    );
    expect(await resolver.resolve(), 'pisces');
  });

  test('weekly overview has seven weekday readings', () {
    final sign = AstrologyContentCatalogue.signById('virgo')!;
    final week = AstrologyWeeklyCopy.week(sign, now: DateTime(2026, 8, 10));
    expect(week, hasLength(7));
    expect(week.map((d) => d.label).toList(), [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ]);
    expect(week.every((d) => d.text.contains('Başak')), isTrue);
    expect(week.map((d) => d.text).toSet().length, greaterThan(1));
  });

  test('kind note distinguishes burç from natal chart', () {
    expect(AstrologyReferenceKindNote.label, 'Önizleme');
    expect(AstrologyReferenceKindNote.detail.toLowerCase(), contains('yansıma'));
    expect(AstrologyReferenceKindNote.detail.toLowerCase(), isNot(contains('doğum haritası')));
    expect(AstrologyReferenceKindNote.detail.toLowerCase(), isNot(contains('natal')));
    expect(AstrologyReferenceKindNote.detail.toLowerCase(), isNot(contains('elimde')));
  });
}
