/// Paylaş control — cancel is silent, missing share is calm.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/discovery_share/copy/discovery_share_copy.dart';
import 'package:oracly_new/features/discovery_share/providers/discovery_share_providers.dart';
import 'package:oracly_new/features/discovery_share/services/discovery_share_builder.dart';
import 'package:oracly_new/features/discovery_share/services/discovery_share_port.dart';
import 'package:oracly_new/features/discovery_share/widgets/discovery_share_action.dart';
import 'package:oracly_new/shared/widgets/oracly_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'discovery_share_fakes.dart';

void main() {
  // Sharing logs analytics, which reads real local storage.
  Future<LocalStorage> storage() async {
    SharedPreferences.setMockInitialValues({});
    return LocalStorage.open();
  }

  testWidgets('Paylaş shows a calm note when share is unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(await storage()),
          discoverySharePortProvider.overrideWithValue(
            const UnavailableDiscoveryShare(),
          ),
          discoveryShareRendererProvider.overrideWithValue(
            const SilentDiscoveryShareCard(),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DiscoveryShareAction(
              discovery: DiscoveryShareBuilder.astrology(
                innerTheme: 'Nehir gibi akış',
                signName: 'Aslan',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text(DiscoveryShareCopy.share));
    await tester.pump();
    await tester.pump();
    expect(find.text(DiscoveryShareCopy.unavailable), findsOneWidget);
    expect(find.byType(OraclyButton), findsNothing);
  });

  testWidgets('canceled share does not treat dismissal as an error', (
    tester,
  ) async {
    final port = RecordingDiscoveryShare()
      ..next = DiscoveryShareOutcome.canceled;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(await storage()),
          discoverySharePortProvider.overrideWithValue(port),
          discoveryShareRendererProvider.overrideWithValue(
            const SilentDiscoveryShareCard(),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DiscoveryShareAction(
              discovery: DiscoveryShareBuilder.starMap(highlight: 'Umut'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text(DiscoveryShareCopy.share));
    await tester.pump();
    await tester.pump();
    expect(port.last, isNotNull);
    expect(find.text(DiscoveryShareCopy.unavailable), findsNothing);
  });
}
