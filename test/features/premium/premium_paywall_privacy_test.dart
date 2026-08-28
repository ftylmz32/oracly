/// Paywall footer exposes the existing Privacy destination.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/navigation/oracly_routes.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_reference_links.dart';
import 'package:oracly_new/features/privacy/presentation/screens/privacy_control_center_screen.dart';
import 'package:oracly_new/screens/privacy/privacy_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => OraclyL10n.bind('en'));

  testWidgets('paywall links open existing Privacy route', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: MaterialApp(
          routes: {
            OraclyRoutes.privacy: (_) => const PrivacyScreen(),
          },
          home: const Scaffold(body: PremiumReferenceLinks()),
        ),
      ),
    );

    expect(find.text(OraclyL10n.t(L10nKeys.privacy)), findsOneWidget);
    await tester.tap(find.text(OraclyL10n.t(L10nKeys.privacy)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(PrivacyScreen), findsOneWidget);
    expect(find.byType(PrivacyControlCenterScreen), findsOneWidget);
  });
}
