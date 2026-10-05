/// WAVE 2.7 — account switch must never show user A's birth information
/// (date / place / derived sun sign) to user B: not through the cached
/// providers, not through the SoulMate birth prefill, not through a leftover
/// disk record. Real lifecycle: UserLocalDataIsolation.onSignedIn wipes the
/// device-local birth chart and AccountSwitchRefreshHost invalidates caches.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/auth/account_switch_refresh_host.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_birth_chart_repository.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/birth_chart/data/birth_chart_record_mapper.dart';
import 'package:oracly_new/features/birth_chart/models/birth_profile.dart';
import 'package:oracly_new/features/birth_chart/providers/birth_information_provider.dart';
import 'package:oracly_new/features/birth_chart/services/natal_chart_calculator.dart';
import 'package:oracly_new/features/premium/copy/soul_mate_copy.dart';
import 'package:oracly_new/features/premium/presentation/screens/soul_mate_draw_screen.dart';
import 'package:oracly_new/core/config/app_environment.dart';
import 'package:oracly_new/core/l10n/oracly_format.dart';
import 'package:oracly_new/features/premium/providers/premium_providers.dart';
import 'package:oracly_new/features/premium/services/premium_dev_override.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_path_provider.dart';

class _Probe extends ConsumerWidget {
  const _Probe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final birth = ref.watch(birthInformationProvider).valueOrNull;
    final sun = ref.watch(savedSunSignProvider);
    return Text(
      'place=${birth?.birthPlace ?? 'none'} '
      'date=${birth == null ? 'none' : birth.birthDate.toIso8601String().substring(0, 10)} '
      'sun=${sun?.name ?? 'none'}',
      textDirection: TextDirection.ltr,
    );
  }
}

final _userA = BirthProfile(
  birthDate: DateTime(1995, 8, 15), // Leo
  birthPlace: 'İstanbul',
  birthTime: DateTime(1995, 8, 15, 6, 30),
  birthTimeKnown: true,
  latitude: 41.01,
  longitude: 28.97,
);
final _userB = BirthProfile(
  birthDate: DateTime(1990, 4, 2), // Aries
  birthPlace: 'Ankara',
);

const _aText = 'place=İstanbul date=1995-08-15 sun=leo';
const _bText = 'place=Ankara date=1990-04-02 sun=aries';
const _noneText = 'place=none date=none sun=none';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorage storage;
  late UserLocalDataIsolation isolation;

  setUp(() async {
    await installTestPathProvider('oracly-wave27-birth-');
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorage(await SharedPreferences.getInstance());
    isolation = UserLocalDataIsolation(
      storage,
      secureStorage: InMemorySecureStorage(),
    );
  });

  Widget app() => ProviderScope(
        overrides: [localStorageProvider.overrideWithValue(storage)],
        child: const AccountSwitchRefreshHost(
          child: MaterialApp(home: Scaffold(body: _Probe())),
        ),
      );

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(_Probe)));

  Future<void> seed(WidgetTester tester, BirthProfile profile) async {
    final container = containerOf(tester);
    await tester.runAsync(() async {
      final chart = const NatalChartCalculator().calculate(profile);
      await container
          .read(birthChartRepositoryProvider)
          .save(BirthChartRecordMapper.toRecord(chart));
    });
    container.invalidate(birthInformationProvider);
    await tester.pumpAndSettle();
  }

  Future<void> signIn(WidgetTester tester, String uid) async {
    await tester.runAsync(() => isolation.onSignedIn(uid));
    await tester.pumpAndSettle();
    expect(storage.getString(UserLocalDataIsolation.ownerKey), uid,
        reason: 'precondition: owner switch committed (wipe complete)');
  }

  testWidgets('A→B: user B never sees user A birth date, place or sun sign',
      (tester) async {
    await signIn(tester, 'user-a');
    await tester.pumpWidget(app());
    await seed(tester, _userA);
    expect(find.text(_aText), findsOneWidget, reason: 'A sees own data');

    await signIn(tester, 'user-b');

    expect(find.text(_noneText), findsOneWidget,
        reason: 'B must not see A date/place/sun sign');
    expect(find.textContaining('İstanbul'), findsNothing);
    expect(
      await tester.runAsync(
        () => containerOf(tester).read(birthChartRepositoryProvider).getLatest(),
      ),
      isNull,
    );
  });

  testWidgets('same user re-sign-in keeps its own birth information',
      (tester) async {
    await signIn(tester, 'user-a');
    await tester.pumpWidget(app());
    await seed(tester, _userA);

    await signIn(tester, 'user-a');

    expect(find.text(_aText), findsOneWidget);
  });

  testWidgets('B own data is B only; A→B→A never carries B data back to A',
      (tester) async {
    await signIn(tester, 'user-a');
    await tester.pumpWidget(app());
    await seed(tester, _userA);

    await signIn(tester, 'user-b');
    await seed(tester, _userB);
    expect(find.text(_bText), findsOneWidget, reason: 'B sees only B');
    expect(find.textContaining('İstanbul'), findsNothing);

    await signIn(tester, 'user-a');

    expect(find.textContaining('Ankara'), findsNothing,
        reason: 'B data must not reach A');
    expect(find.textContaining('aries'), findsNothing);
    // D keeps birth data device-local and wipes it on any owner switch, so
    // A's earlier record is not restored here (by design, not a leak).
    expect(find.text(_noneText), findsOneWidget);
  });

  test('leftover A-stamped disk record (incomplete wipe) is invisible to B '
      'and never overwritten by B', () async {
    final chart = const NatalChartCalculator().calculate(_userA);
    final aRecord =
        BirthChartRecordMapper.toRecord(chart).copyWith(ownerId: 'user-a');
    await storage.setString(
      LocalBirthChartRepository.storageKey,
      jsonEncode(aRecord.toJson()),
    );

    final asB = LocalBirthChartRepository(storage, ownerId: 'user-b');
    expect(await asB.getLatest(), isNull);
    await asB.save(BirthChartRecordMapper.toRecord(
      const NatalChartCalculator().calculate(_userB),
    ));
    final asA = LocalBirthChartRepository(storage, ownerId: 'user-a');
    expect((await asA.getLatest())?.ownerId, 'user-a',
        reason: 'fail closed: B cannot overwrite A');
    expect(await asB.getLatest(), isNull);
  });

  testWidgets('SoulMate birth prefill: B form never starts with A birth date '
      '(A positive control prefills)', (tester) async {
    // Same dev-Premium unlock as soul_mate_durable_test so the form renders
    // (without Premium the screen shows the upsell, not the form).
    PremiumDevOverride.debugEnvironment = AppEnvironment.development;
    PremiumDevOverride.debugFlag = true;
    addTearDown(PremiumDevOverride.resetDebug);
    final aDate = OraclyFormat.dateNumeric(_userA.birthDate);

    // The SoulMate screen animates continuously: bounded pumps, no settle.
    Future<void> settleScreen() async {
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
    }

    Future<void> openSoulMate(NavigatorState nav) async {
      await tester.runAsync(
        () => containerOf(tester).read(premiumStatusProvider).load(),
      );
      nav.push(
        MaterialPageRoute<void>(builder: (_) => const SoulMateDrawScreen()),
      );
      await settleScreen();
    }

    await signIn(tester, 'user-a');
    await tester.pumpWidget(app());
    await seed(tester, _userA);
    final nav = tester.state<NavigatorState>(find.byType(Navigator));

    await openSoulMate(nav);
    expect(find.text(SoulMateCopy.birthLabel), findsOneWidget,
        reason: 'control: the form is really rendered');
    expect(find.text(aDate), findsOneWidget,
        reason: 'control: A form is prefilled with A birth date');
    nav.pop();
    await settleScreen();

    await tester.runAsync(() => isolation.onSignedIn('user-b'));
    await settleScreen();
    expect(storage.getString(UserLocalDataIsolation.ownerKey), 'user-b');
    await openSoulMate(nav);

    expect(find.text(SoulMateCopy.birthLabel), findsOneWidget,
        reason: 'the form is rendered for B');
    expect(find.text(aDate), findsNothing,
        reason: 'B form must never carry A birth date');
    expect(find.text(SoulMateCopy.birthHint), findsOneWidget,
        reason: 'B form starts empty');
  });
}
