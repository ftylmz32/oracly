/// Birthday ritual — real birth date only, no fabricated astrology.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/copy/birthday_ritual.dart';
import 'package:oracly_new/core/copy/home_personal_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/universe/oracly_ritual_time.dart';
import 'package:oracly_new/core/universe/oracly_universe_layer.dart';
import 'package:oracly_new/core/universe/oracly_universe_state.dart';
import 'package:oracly_new/features/birth_chart/models/birth_profile.dart';
import 'package:oracly_new/features/birth_chart/providers/birth_information_provider.dart';
import 'package:oracly_new/features/home/reference/home_reference_hero.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('missing birth date never shows the birthday state', () {
    expect(
      BirthdayRitual.isToday(
        birthDate: null,
        now: DateTime(2026, 8, 13),
      ),
      isFalse,
    );
    expect(
      HomePersonalCopy.greeting(
        time: OraclyRitualTime.evening,
        profileName: 'Fatih',
      ),
      'İyi akşamlar, Fatih',
    );
  });

  test('matching month and day unlocks the quiet birthday copy', () {
    final birth = DateTime(1994, 8, 13);
    expect(
      BirthdayRitual.isToday(birthDate: birth, now: DateTime(2026, 8, 13, 21)),
      isTrue,
    );
    expect(
      HomePersonalCopy.greeting(
        time: OraclyRitualTime.evening,
        isBirthday: true,
      ),
      BirthdayRitual.greeting,
    );
    expect(
      HomePersonalCopy.ritualWelcome(
        OraclyRitualTime.evening,
        isBirthday: true,
      ),
      BirthdayRitual.cardBody,
    );
    expect(BirthdayRitual.greeting.toLowerCase(), isNot(contains('burç')));
    expect(BirthdayRitual.cardBody.toLowerCase(), isNot(contains('yükselen')));
  });

  test('a different calendar day stays ordinary', () {
    expect(
      BirthdayRitual.isToday(
        birthDate: DateTime(1994, 3, 12),
        now: DateTime(2026, 8, 13),
      ),
      isFalse,
    );
  });

  testWidgets('hero keeps Merhaba even on a birthday', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    final today = OraclyUniverseState.current(DateTime(2026, 8, 13, 20));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          isFirstSessionProvider.overrideWith((ref) async => false),
          birthInformationProvider.overrideWith(
            (ref) async => BirthProfile(
              birthDate: DateTime(1994, 8, 13),
              birthPlace: 'İstanbul',
            ),
          ),
        ],
        child: MaterialApp(
          home: OraclyUniverseScope(
            state: today,
            child: const Scaffold(body: HomeReferenceHero()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Merhaba,'), findsOneWidget);
    expect(find.textContaining('Bugün senin için'), findsOneWidget);
    expect(find.text(BirthdayRitual.greeting), findsNothing);
    expect(find.textContaining('İyi akşamlar'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
