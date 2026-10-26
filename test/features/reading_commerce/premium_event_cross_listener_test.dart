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
/// Tests named "MEASURED" record current behavior as a fact (they pass on
/// today's code); the safety tests assert what must never happen.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_wipe.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/reading_commerce/services/reading_purchase_disk.dart';
import 'package:oracly_new/features/reading_commerce/services/reading_purchase_monitor.dart';
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
      final memory = DiskReadingPurchases();
      final kind = await w.tracker(memory).accept(_premiumPurchased);
      expect(kind, ReadingBuyKind.failed);
      expect(w.completed, isEmpty, reason: 'would acknowledge the subscription');
      expect(await memory.load(), isEmpty);
    });

    test('unavailable (QA debug: App Check; or offline): no grant, no '
        'completePurchase', () async {
      w.verdict = (_) => ReadingVerifyOutcome.unavailable;
      final kind = await w.tracker(DiskReadingPurchases()).accept(_premiumPurchased);
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
      final memory = DiskReadingPurchases();
      final t = w.tracker(memory);
      await t.accept(_premiumPurchased);
      final coffee = _event('app.oracly.reading.coffee', 'coffee-token',
          ReadingPurchaseStatus.purchased);
      expect(await t.accept(coffee), ReadingBuyKind.granted);
      expect(w.completed, ['app.oracly.reading.coffee']);
      expect(await memory.load(), isEmpty);
    });
  });

  group('MEASURED: what the reading path does with a Premium event', () {
    test('it sends the Premium token to the reading verify endpoint', () async {
      await w.tracker(DiskReadingPurchases()).accept(_premiumPurchased);
      expect(w.verified, ['account-A:app.oracly.premium.yearly']);
    });

    test('while verify is unavailable, the Premium token stays in plain '
        'SharedPreferences and is retried on every app start', () async {
      w.verdict = (_) => ReadingVerifyOutcome.unavailable;
      await w.tracker(DiskReadingPurchases()).accept(_premiumPurchased);
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList('reading_commerce_unfinished_v1');
      expect(raw, hasLength(1));
      expect(raw!.single, contains(_premiumToken));
      // Three "app starts": a fresh tracker over the same disk each time.
      for (var i = 0; i < 3; i++) {
        await w.tracker(DiskReadingPurchases()).resume();
      }
      expect(w.verified, hasLength(4)); // first accept + 3 resumes
      expect(w.completed, isEmpty);
    });

    test('it self-clears once the backend can answer (rejected)', () async {
      w.verdict = (_) => ReadingVerifyOutcome.unavailable;
      await w.tracker(DiskReadingPurchases()).accept(_premiumPurchased);
      w.verdict = (_) => ReadingVerifyOutcome.rejected;
      await w.tracker(DiskReadingPurchases()).resume();
      expect(await DiskReadingPurchases().load(), isEmpty);
    });

    test('a Premium PENDING (slow card) event is stored and never revisited '
        'by resume, so it lingers until the store sends a final event', () async {
      final pending = _event('app.oracly.premium.yearly', 'premium-pending',
          ReadingPurchaseStatus.pending);
      expect(await w.tracker(DiskReadingPurchases()).accept(pending),
          ReadingBuyKind.pending);
      await w.tracker(DiskReadingPurchases()).resume();
      expect(w.verified, isEmpty);
      expect((await DiskReadingPurchases().load()).single.status,
          ReadingPurchaseStatus.pending);
    });

    test('account switch: the account wipe does not clear the reading '
        'memory, so A\'s token is re-verified under B', () async {
      w.verdict = (_) => ReadingVerifyOutcome.unavailable;
      await w.tracker(DiskReadingPurchases()).accept(_premiumPurchased);
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final wipe = await UserLocalDataWipe.run(
        storage,
        secureStorage: InMemorySecureStorage(),
      );
      expect(wipe.isComplete, isTrue);
      expect(await DiskReadingPurchases().load(), hasLength(1),
          reason: 'survived the A→B wipe');
      w.signedIn = 'account-B';
      w.verdict = (_) => ReadingVerifyOutcome.rejected;
      await w.tracker(DiskReadingPurchases()).resume();
      expect(w.verified.last, 'account-B:app.oracly.premium.yearly');
      expect(w.completed, isEmpty);
      expect(await DiskReadingPurchases().load(), isEmpty);
    });

    test('the monitor reports the Premium event to reading listeners as a '
        'reading failure', () async {
      final updates = StreamController<List<ReadingPurchaseUpdate>>();
      final monitor = ReadingPurchaseMonitor(
        tracker: w.tracker(DiskReadingPurchases()),
        updates: updates.stream,
        buyProduct: (_) async => true,
        storePrices: () async => const {},
      );
      final seen = <String>[];
      monitor.addListener((kind, productId) => seen.add('${kind.name}:$productId'));
      await monitor.start();
      updates.add([_premiumPurchased]);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(seen, ['failed:app.oracly.premium.yearly']);
      await updates.close();
      monitor.dispose();
    });
  });
}
