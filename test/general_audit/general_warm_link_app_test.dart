/// G0 — the real [OraclyApp] owns warm deep links before Flutter's
/// default `pushNamed(uri.path)` handling can stack a route.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/oracly_app.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/navigation/oracly_navigator_key.dart';
import 'package:oracly_new/features/discovery_share/models/shareable_discovery.dart';
import 'package:oracly_new/features/share_reopen/models/share_public_payload.dart';
import 'package:oracly_new/features/share_reopen/services/share_link_inbox.dart';
import 'package:oracly_new/features/share_reopen/services/share_link_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({'settings_language': 'tr'});
  final storage = LocalStorage(await SharedPreferences.getInstance());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [localStorageProvider.overrideWithValue(storage)],
      child: const OraclyApp(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(ShareLinkInbox.instance.clearForTest);
  tearDown(ShareLinkInbox.instance.clearForTest);

  testWidgets('warm share link is queued for the gate, never pushNamed',
      (tester) async {
    await _pumpApp(tester);
    final link = ShareLinkParser.build(
      const SharePublicPayload(
        id: 'ab12cd34ef56ab78',
        kind: DiscoveryShareKind.coffee,
        highlight: 'Sakin',
      ),
    );
    final handled = await tester.binding.handlePushRoute(link.toString());
    await tester.pump(const Duration(milliseconds: 100));
    expect(handled, isTrue);
    expect(ShareLinkInbox.instance.hasPendingForTest, isTrue);
    expect(oraclyNavigatorKey.currentState!.canPop(), isFalse);
  });

  testWidgets('warm unsupported links push nothing', (tester) async {
    await _pumpApp(tester);
    for (final raw in [
      'oracly://share/not-a-token',
      'oracly://open/home',
      'oracly://open/soul-mate',
      'oracly://open/numerology',
    ]) {
      expect(await tester.binding.handlePushRoute(raw), isTrue);
      await tester.pump(const Duration(milliseconds: 100));
      expect(oraclyNavigatorKey.currentState!.canPop(), isFalse, reason: raw);
    }
    expect(ShareLinkInbox.instance.hasPendingForTest, isFalse);
  });
}
