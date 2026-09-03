/// Onboarding completion order, idempotency, and in-flight guard.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/onboarding_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_onboarding_repository.dart';
import 'package:oracly_new/core/first_session/first_session_intent.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/gems/economy/gem_economy.dart';
import 'package:oracly_new/features/gems/services/gem_starter_grant.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:oracly_new/features/onboarding/services/onboarding_completion.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => OraclyL10n.bind('tr'));

  test('completion marker is written last', () async {
    final log = <String>[];
    await OnboardingCompletion.run(
      persistProfile: () async {},
      requestFirstReading: () async {},
      grantStarterGems: () async {},
      clearDraft: () async {},
      markCompleted: () async {},
      stepLog: log,
    );
    expect(log, ['profile', 'first_reading', 'gems', 'draft', 'complete']);
    expect(log.last, 'complete');
  });

  test('failure before markCompleted leaves onboarding incomplete', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final onboarding = LocalOnboardingRepository(storage);
    final log = <String>[];

    await expectLater(
      OnboardingCompletion.run(
        persistProfile: () async => log.add('profile'),
        requestFirstReading: () async => log.add('first_reading'),
        grantStarterGems: () async {
          log.add('gems');
          throw StateError('gems failed');
        },
        clearDraft: () async => log.add('draft'),
        markCompleted: () async {
          log.add('complete');
          await onboarding.markCompleted();
        },
      ),
      throwsA(isA<StateError>()),
    );

    expect(log, ['profile', 'first_reading', 'gems']);
    expect(await onboarding.isCompleted(), isFalse);
  });

  test('retry after partial failure grants starter gems once', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final wallet = GemWalletService(GemWalletStore(storage));
    final grant = GemStarterGrant(wallet, storage);
    final onboarding = LocalOnboardingRepository(storage);
    var blowGems = true;

    Future<void> attempt() => OnboardingCompletion.run(
      persistProfile: () async {},
      requestFirstReading: () =>
          FirstSessionIntent.requestFirstReading(storage),
      grantStarterGems: () async {
        if (blowGems) {
          blowGems = false;
          throw StateError('transient');
        }
        await grant.ensureOnce();
      },
      clearDraft: () async {},
      markCompleted: onboarding.markCompleted,
    );

    await expectLater(attempt(), throwsA(isA<StateError>()));
    expect(await onboarding.isCompleted(), isFalse);
    expect(wallet.balance, 0);

    await attempt();
    expect(await onboarding.isCompleted(), isTrue);
    expect(wallet.balance, GemEconomy.starterGrant);

    await grant.ensureOnce();
    expect(wallet.balance, GemEconomy.starterGrant);
  });

  test('completeFailed copy is localized', () {
    expect(OnboardingCopy.completeFailed, isNotEmpty);
    expect(
      OnboardingCopy.completeFailed.toLowerCase(),
      isNot(contains('exception')),
    );
  });
}
