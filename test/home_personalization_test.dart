/// Home personalization — real name or Yolcu; time-band ritual copy.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/copy/first_session_copy.dart';
import 'package:oracly_new/core/copy/home_personal_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/universe/oracly_ritual_time.dart';
import 'package:oracly_new/core/universe/oracly_universe_layer.dart';
import 'package:oracly_new/core/universe/oracly_universe_state.dart';
import 'package:oracly_new/features/home/reference/home_reference_header.dart';
import 'package:oracly_new/features/home/reference/home_reference_hero.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('greeting uses real name and never invents one', () {
    expect(
      HomePersonalCopy.greeting(
        time: OraclyRitualTime.evening,
        profileName: 'Fatih',
      ),
      'İyi akşamlar, Fatih',
    );
    expect(
      HomePersonalCopy.greeting(
        time: OraclyRitualTime.evening,
        profileName: '  ',
      ),
      'İyi akşamlar, ${FirstSessionCopy.homeGuestName}',
    );
    expect(
      HomePersonalCopy.greeting(time: OraclyRitualTime.morning),
      'İyi sabahlar, Yolcu',
    );
  });

  test('ritual welcome follows the four time bands', () {
    expect(
      HomePersonalCopy.ritualWelcome(OraclyRitualTime.morning),
      'Güne acele etmeden bak.',
    );
    expect(
      HomePersonalCopy.ritualWelcome(OraclyRitualTime.afternoon),
      'Bir nefes al, kendine dön.',
    );
    expect(
      HomePersonalCopy.ritualWelcome(OraclyRitualTime.evening),
      'Günü yumuşakça toparla.',
    );
    expect(
      HomePersonalCopy.ritualWelcome(OraclyRitualTime.night),
      'Geceye biraz yer bırak.',
    );
  });

  testWidgets('hero shows fixed Merhaba greeting, not a personalized name',
      (tester) async {
    SharedPreferences.setMockInitialValues({'profile_name': 'Fatih'});
    final storage = await LocalStorage.open();
    final evening = OraclyUniverseState.current(DateTime(2026, 8, 13, 20));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          isFirstSessionProvider.overrideWith((ref) async => false),
        ],
        child: MaterialApp(
          home: OraclyUniverseScope(
            state: evening,
            child: const Scaffold(body: HomeReferenceHero()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Merhaba,'), findsOneWidget);
    expect(find.textContaining('Bugün senin için'), findsOneWidget);
    expect(find.text('İyi akşamlar, Fatih'), findsNothing);
    expect(find.text(HomeReferenceHeader.tagline), findsNothing);
    expect(find.textContaining('Yolcu'), findsNothing);
  });
}
