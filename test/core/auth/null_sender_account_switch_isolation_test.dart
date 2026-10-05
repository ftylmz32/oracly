/// WAVE 2.10 — null-sender account-switch privacy RED gate.
///
/// Palm, legacy Coffee and Coffee V2 controllers are rebuilt on an account
/// switch only indirectly: PrivacyDataRefresh.afterAccountSwitch invalidates
/// readingOperationSenderProvider, and the controllers watch the runner built
/// from it. Without a proxy the sender is null; null -> null is "no change"
/// for Riverpod, so nothing downstream rebuilds.
///
/// Each feature runs twice with the real lifecycle (UserLocalDataIsolation
/// .onSignedIn + AccountSwitchRefreshHost): with a null sender (the latent
/// case) and with a configured sender (control: a fresh closure per build,
/// like a release with a valid proxy). Instrumentation records sender /
/// runner / controller identity, account epoch and owner around the switch.
/// Production code unchanged.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/auth/account_switch_refresh_host.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/providers/backend_providers.dart'
    show localDataOwnerEpochProvider;
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/coffee/coffee_v2/controllers/coffee_v2_flow_controller.dart';
import 'package:oracly_new/features/coffee/coffee_v2/providers/coffee_v2_providers.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/coffee/providers/coffee_providers.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/models/palm_reading.dart';
import 'package:oracly_new/features/palm/providers/palm_providers.dart';
import 'package:oracly_new/features/reading_operation/providers/reading_live_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_path_provider.dart';

class _Probe extends ConsumerWidget {
  const _Probe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palm = ref.watch(palmReadingControllerProvider);
    final coffee = ref.watch(coffeeReadingControllerProvider);
    final v2 = ref.watch(coffeeV2FlowControllerProvider);
    return Text(
      'palm=${palm.reading?.id ?? 'none'} '
      'coffee=${coffee.reading?.id ?? 'none'} '
      'v2=${v2.reading?.id ?? 'none'}',
      textDirection: TextDirection.ltr,
    );
  }
}

/// Identity snapshot of the chain + lifecycle markers.
class _Snap {
  _Snap(ProviderContainer c, LocalStorage storage)
      : sender = c.read(readingOperationSenderProvider),
        runner = c.read(readingFeatureRunnerProvider),
        palm = c.read(palmReadingControllerProvider),
        coffee = c.read(coffeeReadingControllerProvider),
        v2 = c.read(coffeeV2FlowControllerProvider),
        epoch = UserLocalDataIsolation.accountSwitchEpoch.value,
        // What an epoch-watching controller (e.g. Dream) would rebuild on.
        ownerEpoch = c.read(localDataOwnerEpochProvider),
        owner = storage.getString(UserLocalDataIsolation.ownerKey);

  final Object? sender;
  final Object? runner;
  final Object palm;
  final Object coffee;
  final CoffeeV2FlowController v2;
  final int epoch;
  final int ownerEpoch;
  final String? owner;

  String diff(_Snap after) =>
      'sender ${sender == null ? 'null' : 'set'}->'
      '${after.sender == null ? 'null' : 'set'} '
      '(same=${identical(sender, after.sender)}); '
      'runner ${runner == null ? 'null' : 'set'}->'
      '${after.runner == null ? 'null' : 'set'} '
      '(same=${identical(runner, after.runner)}); '
      'palmSame=${identical(palm, after.palm)} '
      'coffeeSame=${identical(coffee, after.coffee)} '
      'v2Same=${identical(v2, after.v2)}; '
      'epoch $epoch->${after.epoch}; '
      'localDataOwnerEpochProvider $ownerEpoch->${after.ownerEpoch}; '
      'owner $owner->${after.owner}';
}

PalmReading _palm(String id) => PalmReading(
      id: id,
      createdAt: DateTime.utc(2026, 10, 5),
      hand: PalmHand.left,
      overall: 'private palm of $id',
      takeaway: 'private takeaway of $id',
    );

CoffeeReading _coffee(String id) => CoffeeReading(
      id: id,
      createdAt: DateTime.utc(2026, 10, 5),
      overall: 'private cup of $id',
      love: 'private love of $id',
      career: '',
      money: '',
      nearFuture: '',
      takeaway: '',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorage storage;
  late UserLocalDataIsolation isolation;

  setUp(() async {
    await installTestPathProvider('oracly-wave210-');
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorage(await SharedPreferences.getInstance());
    isolation = UserLocalDataIsolation(
      storage,
      secureStorage: InMemorySecureStorage(),
    );
  });

  Widget app({required bool senderConfigured}) => ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          if (senderConfigured)
            // A configured release: a NEW sender closure on every rebuild.
            readingOperationSenderProvider.overrideWith(
              (ref) => (method, path, body) async => null,
            ),
          // Not configured: the real provider resolves no proxy -> null.
        ],
        child: const AccountSwitchRefreshHost(child: _Probe()),
      );

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(_Probe)));

  Future<void> signIn(WidgetTester tester, String uid) async {
    await tester.runAsync(() => isolation.onSignedIn(uid));
    await tester.pumpAndSettle();
    expect(storage.getString(UserLocalDataIsolation.ownerKey), uid,
        reason: 'precondition: owner switch committed (wipe complete)');
  }

  for (final configured in [false, true]) {
    final mode = configured ? 'CONTROL non-null sender' : 'NULL sender';

    group(mode, () {
      testWidgets('Palm: user B never sees user A open Palm reading',
          (tester) async {
        await signIn(tester, 'user-a');
        await tester.pumpWidget(app(senderConfigured: configured));
        final c = containerOf(tester);
        expect(c.read(readingOperationSenderProvider) == null, !configured,
            reason: 'precondition: sender mode');
        c.read(palmReadingControllerProvider).openSaved(_palm('palm-of-user-a'));
        await tester.pumpAndSettle();
        expect(find.textContaining('palm=palm-of-user-a'), findsOneWidget);
        final before = _Snap(c, storage);

        await signIn(tester, 'user-b');
        final trace = before.diff(_Snap(c, storage));

        expect(find.textContaining('palm=none'), findsOneWidget,
            reason: 'B sees A open Palm reading. $trace');
        expect(c.read(palmReadingControllerProvider).reading, isNull,
            reason: trace);
      });

      testWidgets('legacy Coffee: user B never sees user A open Coffee reading',
          (tester) async {
        await signIn(tester, 'user-a');
        await tester.pumpWidget(app(senderConfigured: configured));
        final c = containerOf(tester);
        c
            .read(coffeeReadingControllerProvider)
            .openSaved(_coffee('coffee-of-user-a'));
        await tester.pumpAndSettle();
        expect(find.textContaining('coffee=coffee-of-user-a'), findsOneWidget);
        final before = _Snap(c, storage);

        await signIn(tester, 'user-b');
        final trace = before.diff(_Snap(c, storage));

        expect(find.textContaining('coffee=none'), findsOneWidget,
            reason: 'B sees A open Coffee reading. $trace');
        expect(c.read(coffeeReadingControllerProvider).reading, isNull,
            reason: trace);
      });

      testWidgets('Coffee V2: no user A flow state is visible to user B',
          (tester) async {
        await signIn(tester, 'user-a');
        await tester.pumpWidget(app(senderConfigured: configured));
        final c = containerOf(tester);
        await tester.pumpAndSettle();
        final v2A = c.read(coffeeV2FlowControllerProvider);
        // Strongest A state the product can create in this runtime: without
        // a sender Coffee V2 is unavailable (no capture, no result path).
        expect(v2A.available, configured,
            reason: 'precondition: Coffee V2 availability follows the sender');
        final before = _Snap(c, storage);

        await signIn(tester, 'user-b');
        final after = _Snap(c, storage);
        final trace = before.diff(after);

        expect(find.textContaining('v2=none'), findsOneWidget, reason: trace);
        expect(after.v2.reading, isNull, reason: trace);
        expect(after.v2.previewCandidate, isNull, reason: trace);
        if (configured) {
          expect(identical(after.v2, before.v2), isFalse,
              reason: 'control: rebuilt for the new owner. $trace');
        }
      });
    });
  }
}
