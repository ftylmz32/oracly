/// G1 — account switch A → B: reading transport and OR start clean for B.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/companion/providers/companion_providers.dart';
import 'package:oracly_new/features/privacy/services/privacy_data_refresh.dart';
import 'package:oracly_new/features/reading_operation/providers/reading_live_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'g1_or_support.dart';

void main() {
  setUp(() => OraclyL10n.bind('en'));

  testWidgets('switching account rebuilds the reading sender and clears the '
      'OR handoff', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    final companion = g1Companion(ai: G1ScriptedAi(), repo: G1ThreadRepo());
    companion.applyReadingHandoff(g1FirstTarot);
    var senderBuilds = 0;

    await tester.pumpWidget(ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
        readingOperationSenderProvider.overrideWith((ref) {
          senderBuilds++;
          return (method, path, body) async => null;
        }),
        companionControllerProvider.overrideWith((ref) => companion),
      ],
      child: MaterialApp(
        home: Consumer(
          builder: (context, ref, _) => TextButton(
            onPressed: () => PrivacyDataRefresh.afterAccountSwitch(ref),
            child: const Text('switch'),
          ),
        ),
      ),
    ));
    final container =
        ProviderScope.containerOf(tester.element(find.text('switch')));
    final runnerBefore = container.read(readingFeatureRunnerProvider);
    expect(senderBuilds, 1);

    await tester.tap(find.text('switch'));
    await tester.pump();

    expect(container.read(readingFeatureRunnerProvider),
        isNot(same(runnerBefore)));
    expect(senderBuilds, 2);
    expect(companion.readingContext, isNull);
  });
}
