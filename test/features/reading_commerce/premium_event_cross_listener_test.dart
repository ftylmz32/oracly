/// Gate B2 finding — both purchase listeners receive every Google Play event.
/// The reading-commerce chain (ReadingCommerceBuyer → ReadingPurchaseMonitor
/// → ReadingPurchaseTracker → DiskReadingPurchases) has no product filter, so
/// a Premium subscription event reaches it too (seen on the real device:
/// `[ReadingSender] blocked POST /v1/reading-entitlements/verify`).
///
/// Real tracker, monitor, disk memory and account wipe; only the server
/// verdict and the store's completePurchase are counting fakes. The verdicts
/// mirror the real wiring: the backend refuses a non-reading product with
/// 400 (`rejected`), App Check / network failures read as `unavailable`.
///
/// Since the reading-commerce fix (26 Oct 2026) the listener drops Premium
/// events at the stream (reading_commerce_owner_safety_test.dart). These
/// tests keep the tracker-level defence in depth: even if a Premium event
/// reached the tracker, it would never be granted or finished.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/reading_commerce/services/reading_purchase_tracker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_path_provider.dart';

const _premiumToken = 'premium-yearly-token';

ReadingPurchaseUpdate _event(
  String productId,
  String token,
  ReadingPurchaseStatus status,
) => ReadingPurchaseUpdate(
  productId: productId,
  token: token,
  purchaseId: 'GPA.$token',
  status: status,
);

final _premiumPurchased = _event(
  'app.oracly.premium.yearly',
  _premiumToken,
  ReadingPurchaseStatus.purchased,
);

/// The server and the store, as seen from the tracker.
class _World {
  ReadingVerifyOutcome Function(ReadingPurchaseUpdate) verdict =
      (u) => u.productId.startsWith('app.oracly.reading.')
          ? ReadingVerifyOutcome.granted
          : ReadingVerifyOutcome.rejected; // backend: unknown product → 400
  String signedIn = 'account-A';
  final verified = <String>[]; // "<account>:<productId>"
  final completed = <String>[]; // productIds finished at the store

  ReadingPurchaseTracker tracker(ReadingPurchaseMemory memory) =>
      ReadingPurchaseTracker(
        memory: memory,
        verify: (u) async {
          verified.add('$signedIn:${u.productId}');
          return verdict(u);
        },
        complete: (u) async => completed.add(u.productId),
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _World w;

  setUp(() async {
    await installTestPathProvider('oracly-cross-listener-');
    SharedPreferences.setMockInitialValues({});
    w = _World();
  });

  group('safety: a Premium event never becomes a reading grant or an ack', () {
    test('rejected by the backend (store build): no reading grant, no '
        'completePurchase, nothing left behind', () async {
      final memory = MemoryReadingPurchases();
      final kind = await w.tracker(memory).accept(_premiumPurchased);
      expect(kind, ReadingBuyKind.failed);
      expect(w.completed, isEmpty, reason: 'would acknowledge the subscription');
      expect(await memory.load(), isEmpty);
    });

    test('unavailable (QA debug: App Check; or offline): no grant, no '
        'completePurchase', () async {
      w.verdict = (_) => ReadingVerifyOutcome.unavailable;
      final kind = await w.tracker(MemoryReadingPurchases()).accept(_premiumPurchased);
      expect(kind, ReadingBuyKind.failed);
      expect(w.completed, isEmpty);
    });

    test('only a backend `granted` could ever finish it: the reading path '
        'acknowledges whatever product the server grants', () async {
      // The backend's reading catalog refuses non-reading products (see
      // backend/tests/reading-commerce-premium-product.test.ts), so this
      // verdict cannot happen for Premium today; it shows the one coupling.
      w.verdict = (_) => ReadingVerifyOutcome.granted;
      await w.tracker(MemoryReadingPurchases()).accept(_premiumPurchased);
      expect(w.completed, ['app.oracly.premium.yearly']);
    });

    test('a legitimate reading purchase still works next to it', () async {
      final memory = MemoryReadingPurchases();
      final t = w.tracker(memory);
      await t.accept(_premiumPurchased);
      final coffee = _event('app.oracly.reading.coffee', 'coffee-token',
          ReadingPurchaseStatus.purchased);
      expect(await t.accept(coffee), ReadingBuyKind.granted);
      expect(w.completed, ['app.oracly.reading.coffee']);
      expect(await memory.load(), isEmpty);
    });
  });
}
