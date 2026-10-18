/// Encounter V2.4B: gentle Home invite for a missing name or birth date.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/auth/user_local_data_wipe.dart';
import 'package:oracly_new/core/copy/onboarding_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_onboarding_repository.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/birth_chart/models/birth_profile.dart';
import 'package:oracly_new/features/birth_chart/providers/birth_chart_providers.dart';
import 'package:oracly_new/features/birth_chart/providers/birth_information_provider.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/gems/services/gem_starter_grant.dart';
import 'package:oracly_new/features/home/invite/home_invite_card.dart';
import 'package:oracly_new/features/home/invite/home_invite_copy.dart';
import 'package:oracly_new/features/home/invite/home_invite_providers.dart';
import 'package:oracly_new/features/home/invite/home_invite_store.dart';
import 'package:oracly_new/features/home/master/home_master_page.dart';
import 'package:oracly_new/features/onboarding/encounter/encounter_complete_screen.dart';
import 'package:oracly_new/features/onboarding/encounter/encounter_name_scene.dart';
import 'package:oracly_new/features/onboarding/encounter/encounter_sky_scene.dart';
import 'package:oracly_new/shared/widgets/oracly_pressable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

const _ownerA = 'owner-a';
const _ownerB = 'owner-b';
final _now = DateTime(2026, 10, 17, 10);

/// Fixed frames: encounter heroes never settle.
Future<void> _settle(WidgetTester tester, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// No ensureVisible: it would also scroll the horizontal scene PageView.
Future<void> _press(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).last);
  await _settle(tester);
}

Future<LocalStorage> _storage(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return LocalStorage.open();
}

ProviderContainer _container(
  LocalStorage storage, {
  List<Override> overrides = const [],
}) {
  final c = ProviderContainer(
    overrides: [
      localStorageProvider.overrideWithValue(storage),
      secureStorageProvider.overrideWithValue(InMemorySecureStorage()),
      homeInviteClockProvider.overrideWithValue(() => _now),
      ...overrides,
    ],
  );
  addTearDown(c.dispose);
  return c;
}

BirthProfile _birth({DateTime? time, String place = 'Belirtilmedi'}) =>
    BirthProfile(
      birthDate: DateTime(1994, 6, 12),
      birthPlace: place,
      birthTime: time,
      birthTimeKnown: time != null,
    );

/// Reads the visible decision once both stores have answered.
Future<bool> _visible(ProviderContainer c) async {
  await c.read(userProfileProvider.future);
  await c.read(birthInformationProvider.future);
  return c.read(homeInviteVisibleProvider);
}

Widget _home(
  LocalStorage storage, {
  Size size = const Size(390, 844),
  double scale = 1,
  List<Override> overrides = const [],
  DateTime Function()? clock,
}) {
  return buildProviderScopeHarness(
    storage: storage,
    overrides: [
      homeInviteClockProvider.overrideWithValue(clock ?? () => _now),
      birthInformationProvider.overrideWith((ref) async => null),
      ...overrides,
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(scale),
          padding: const EdgeInsets.only(top: 24, bottom: 34),
        ),
        child: const HomeMasterPage(),
      ),
    ),
  );
}

Future<void> _pumpHome(
  WidgetTester tester,
  LocalStorage storage, {
  Size size = const Size(390, 844),
  double scale = 1,
  DateTime Function()? clock,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    _home(storage, size: size, scale: scale, clock: clock),
  );
  await _settle(tester, 4);
}

Future<void> _revealCard(WidgetTester tester) async {
  final scrollables = find.descendant(
    of: find.byType(HomeMasterPage),
    matching: find.byType(Scrollable),
  );
  if (scrollables.evaluate().isEmpty) return;
  await tester.scrollUntilVisible(
    find.text(HomeInviteCopy.later),
    120,
    scrollable: scrollables.first,
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => OraclyL10n.bind('tr'));

  group('who sees it', () {
    test('copy is the approved Turkish text', () {
      expect(HomeInviteCopy.title, 'Biraz daha tanışalım mı?');
      expect(
        HomeInviteCopy.body,
        'Sana nasıl sesleneceğimizi ve doğum gününü bilirsek bazı '
        'yorumları sana daha özel hazırlayabiliriz.',
      );
      expect(HomeInviteCopy.cta, 'Kendimi tanıtayım');
      expect(HomeInviteCopy.later, 'Şimdi değil');
    });

    test('new guest without name or birth date is invited', () async {
      final storage = await _storage({
        UserLocalDataIsolation.ownerKey: _ownerA,
      });
      final c = _container(storage);
      expect(await _visible(c), isTrue);
      final gaps = c.read(homeInviteGapsProvider)!;
      expect([gaps.name, gaps.birth], [true, true]);
    });

    test('name only missing, or birth only missing, still invites', () async {
      var c = _container(
        await _storage({
          UserLocalDataIsolation.ownerKey: _ownerA,
          'profile_name': 'Deniz',
        }),
      );
      expect(await _visible(c), isTrue);
      expect(c.read(homeInviteGapsProvider)!.name, isFalse);

      c = _container(
        await _storage({UserLocalDataIsolation.ownerKey: _ownerA}),
        overrides: [
          birthInformationProvider.overrideWith((ref) async => _birth()),
        ],
      );
      expect(await _visible(c), isTrue);
      expect(c.read(homeInviteGapsProvider)!.birth, isFalse);
    });

    test(
      'complete profile is never invited, even without time or city',
      () async {
        final c = _container(
          await _storage({
            UserLocalDataIsolation.ownerKey: _ownerA,
            'profile_name': 'Deniz',
          }),
          overrides: [
            birthInformationProvider.overrideWith((ref) async => _birth()),
          ],
        );
        expect(await _visible(c), isFalse);
      },
    );

    test('first reading speaks first', () async {
      final c = _container(
        await _storage({UserLocalDataIsolation.ownerKey: _ownerA}),
        overrides: [firstReadingPendingProvider.overrideWith((ref) => true)],
      );
      expect(await _visible(c), isFalse);
    });

    test('without an owner the birth date is not asked for', () async {
      final c = _container(await _storage({'profile_name': 'Deniz'}));
      expect(await _visible(c), isFalse);
    });
  });

  group('Şimdi değil', () {
    test('snoozes for 7 days and returns after', () async {
      final storage = await _storage({
        UserLocalDataIsolation.ownerKey: _ownerA,
      });
      final c = _container(storage);
      expect(await _visible(c), isTrue);
      await c.read(homeInviteSnoozeProvider.notifier).dismiss();
      expect(c.read(homeInviteVisibleProvider), isFalse);

      final store = HomeInviteStore(storage);
      expect(store.until(), _now.add(const Duration(days: 7)));
      expect(
        store.snoozed(_now.add(const Duration(days: 6, hours: 23))),
        isTrue,
      );
      expect(store.snoozed(_now.add(const Duration(days: 7))), isFalse);

      final later = _container(
        storage,
        overrides: [
          homeInviteClockProvider.overrideWithValue(
            () => _now.add(const Duration(days: 7, minutes: 1)),
          ),
        ],
      );
      expect(await _visible(later), isTrue);
    });

    test('survives an app restart (fresh container, same storage)', () async {
      final storage = await _storage({
        UserLocalDataIsolation.ownerKey: _ownerA,
      });
      await _container(
        storage,
      ).read(homeInviteSnoozeProvider.notifier).dismiss();
      final reopened = await LocalStorage.open();
      expect(await _visible(_container(reopened)), isFalse);
    });

    test('belongs to one account only', () async {
      final storage = await _storage({
        UserLocalDataIsolation.ownerKey: _ownerA,
      });
      await HomeInviteStore(storage).dismiss(_now);
      await storage.setString(UserLocalDataIsolation.ownerKey, _ownerB);
      expect(HomeInviteStore(storage).until(), isNull);
      expect(await _visible(_container(storage)), isTrue);

      await storage.setString(UserLocalDataIsolation.ownerKey, _ownerA);
      await UserLocalDataWipe.run(
        storage,
        secureStorage: InMemorySecureStorage(),
      );
      expect(storage.getString(HomeInviteStore.key), isNull);
    });
  });

  group('Home card', () {
    testWidgets('shows, dismisses and stays dismissed after restart', (
      tester,
    ) async {
      final storage = await _storage({
        UserLocalDataIsolation.ownerKey: _ownerA,
      });
      await _pumpHome(tester, storage);
      await _revealCard(tester);
      expect(find.byType(HomeInviteCard), findsOneWidget);
      expect(find.text(HomeInviteCopy.title), findsOneWidget);
      expect(find.text(HomeInviteCopy.cta), findsOneWidget);

      await tester.tap(find.text(HomeInviteCopy.later));
      await _settle(tester, 3);
      expect(find.text(HomeInviteCopy.title), findsNothing);
      expect(storage.getString(HomeInviteStore.key), isNotNull);

      await tester.pumpWidget(const SizedBox());
      await _pumpHome(tester, await LocalStorage.open());
      expect(find.text(HomeInviteCopy.title), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await _pumpHome(
        tester,
        await LocalStorage.open(),
        clock: () => _now.add(const Duration(days: 8)),
      );
      await _revealCard(tester);
      expect(find.text(HomeInviteCopy.title), findsOneWidget);
    });

    testWidgets('existing user with full profile sees normal Home', (
      tester,
    ) async {
      final storage = await _storage({
        UserLocalDataIsolation.ownerKey: _ownerA,
        'profile_name': 'Deniz',
      });
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _home(
          storage,
          overrides: [
            birthInformationProvider.overrideWith((ref) async => _birth()),
          ],
        ),
      );
      await _settle(tester, 4);
      expect(find.byType(HomeInviteCard), findsOneWidget);
      expect(find.text(HomeInviteCopy.title), findsNothing);
    });

    // Home itself overflows 17 px at 320 / 1.3 with or without the invite
    // (pre-existing); 320 is therefore checked at card level.
    for (final width in [320.0, 360.0, 390.0, 412.0]) {
      testWidgets('fits ${width.toInt()} px at 1.3 text scale', (tester) async {
        final storage = await _storage({
          UserLocalDataIsolation.ownerKey: _ownerA,
        });
        if (width < 360) {
          await tester.binding.setSurfaceSize(Size(width, 640));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(
            buildProviderScopeHarness(
              storage: storage,
              overrides: [homeInviteVisibleProvider.overrideWithValue(true)],
              child: MaterialApp(
                home: MediaQuery(
                  data: MediaQueryData(
                    size: Size(width, 640),
                    textScaler: const TextScaler.linear(1.3),
                  ),
                  child: const Scaffold(
                    body: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: SingleChildScrollView(child: HomeInviteCard()),
                    ),
                  ),
                ),
              ),
            ),
          );
          await _settle(tester, 2);
        } else {
          await _pumpHome(tester, storage, size: Size(width, 800), scale: 1.3);
          await _revealCard(tester);
        }
        expect(tester.takeException(), isNull);
        expect(find.text(HomeInviteCopy.title), findsOneWidget);
        expect(find.text(HomeInviteCopy.body), findsOneWidget);
        final cta = tester.getSize(
          find
              .ancestor(
                of: find.text(HomeInviteCopy.cta),
                matching: find.byType(OraclyPressable),
              )
              .first,
        );
        expect(cta.height, greaterThanOrEqualTo(44));
      });
    }
  });

  group('introduce myself', () {
    late List<bool?> results;

    Future<ProviderContainer> pumpComplete(
      WidgetTester tester,
      LocalStorage storage, {
      required bool askName,
      required bool askBirth,
    }) async {
      await tester.binding.setSurfaceSize(const Size(390, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      results = [];
      await tester.pumpWidget(
        buildProviderScopeHarness(
          storage: storage,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () async => results.add(
                      await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => EncounterCompleteScreen(
                            askName: askName,
                            askBirth: askBirth,
                          ),
                        ),
                      ),
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await _settle(tester);
      return ProviderScope.containerOf(
        tester.element(find.byType(EncounterCompleteScreen)),
      );
    }

    Map<String, Object> seeded() => {
      UserLocalDataIsolation.ownerKey: _ownerA,
      LocalOnboardingRepository.completedKey: true,
      GemStarterGrant.flagKey: true,
      GemWalletStore.balanceKey: 7,
      'profile_readings': 3,
    };

    void expectUntouched(LocalStorage storage) {
      expect(storage.getBool(LocalOnboardingRepository.completedKey), isTrue);
      expect(storage.getBool(GemStarterGrant.flagKey), isTrue);
      expect(storage.getInt(GemWalletStore.balanceKey), 7);
      expect(storage.getInt('profile_readings'), 3);
      expect(storage.getString('onboarding_setup_draft'), isNull);
    }

    testWidgets('asks only the missing name; saves it; no gems, no reset', (
      tester,
    ) async {
      final storage = await _storage(seeded());
      final c = await pumpComplete(
        tester,
        storage,
        askName: true,
        askBirth: false,
      );
      expect(find.byType(EncounterNameScene), findsOneWidget);
      expect(find.byType(EncounterSkyScene), findsNothing);
      await tester.enterText(find.byType(TextField), 'Deniz');
      await _settle(tester, 4);
      await _press(tester, OnboardingCopy.continueLabel);
      expect(results, [true]);
      expect((await c.read(userProfileProvider.future)).name, 'Deniz');
      expectUntouched(storage);
    });

    testWidgets('asks only the missing birth date with the V2.4A wheel', (
      tester,
    ) async {
      final storage = await _storage({...seeded(), 'profile_name': 'Deniz'});
      final c = await pumpComplete(
        tester,
        storage,
        askName: false,
        askBirth: true,
      );
      expect(find.byType(EncounterNameScene), findsNothing);
      await _press(tester, OnboardingCopy.birthPick);
      expect(find.text(OnboardingCopy.birthConfirm), findsOneWidget);
      await _press(tester, OnboardingCopy.birthConfirm);
      await _press(tester, OnboardingCopy.continueLabel);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await _settle(tester, 4);
      expect(results, [true]);
      final birth = await c.read(birthInformationProvider.future);
      expect(birth, isNotNull);
      expect(birth!.birthDate.year, _now.year - 25);
      expect(birth.birthTimeKnown, isFalse);
      expect((await c.read(userProfileProvider.future)).name, 'Deniz');
      expectUntouched(storage);
    });

    testWidgets('Geri from the first scene writes nothing', (tester) async {
      final storage = await _storage(seeded());
      final c = await pumpComplete(
        tester,
        storage,
        askName: true,
        askBirth: true,
      );
      await tester.enterText(find.byType(TextField), 'Deniz');
      await _settle(tester, 4);
      FocusManager.instance.primaryFocus?.unfocus();
      await _settle(tester, 4);
      await _press(tester, OnboardingCopy.backLabel);
      expect(results, [false]);
      expect((await c.read(userProfileProvider.future)).name, isEmpty);
      expect(await c.read(birthInformationProvider.future), isNull);
      expectUntouched(storage);
    });

    testWidgets('back from sky keeps the typed name; skip saves only it', (
      tester,
    ) async {
      final storage = await _storage(seeded());
      final c = await pumpComplete(
        tester,
        storage,
        askName: true,
        askBirth: true,
      );
      await tester.enterText(find.byType(TextField), 'Deniz');
      await _settle(tester, 4);
      await _press(tester, OnboardingCopy.continueLabel);
      expect(find.text(OnboardingCopy.birthPick), findsOneWidget);
      await _press(tester, OnboardingCopy.backLabel);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Deniz',
      );
      await _press(tester, OnboardingCopy.continueLabel);
      await _press(tester, OnboardingCopy.passLabel);
      expect(results, [true]);
      expect((await c.read(userProfileProvider.future)).name, 'Deniz');
      expect(await c.read(birthInformationProvider.future), isNull);
      expectUntouched(storage);
    });

    test('invite disappears once the profile is complete', () async {
      final storage = await _storage({
        UserLocalDataIsolation.ownerKey: _ownerA,
        'profile_name': 'Deniz',
      });
      final c = _container(storage);
      expect(await _visible(c), isTrue);
      await c
          .read(birthChartExperienceServiceProvider)
          .generate(_birth(time: DateTime(1994, 6, 12, 8, 30), place: 'İzmir'));
      c.invalidate(birthInformationProvider);
      expect(await _visible(c), isFalse);
    });
  });
}
