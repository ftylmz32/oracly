/// P4E — a gem cache write held before mutation cannot land in B.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/gems/controllers/gem_wallet_controller.dart';
import 'package:oracly_new/features/gems/copy/gems_copy.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/gems/models/gem_transaction.dart';
import 'package:oracly_new/features/gems/presentation/reference/gems_reference_cards.dart';
import 'package:oracly_new/features/gems/providers/gem_providers.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';

import '../../support/test_path_provider.dart';

final _historyEpoch = StateProvider<int>((ref) => 0);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late int savedEpoch;
  late Directory docsRoot;

  setUp(() async {
    savedEpoch = UserLocalDataIsolation.accountSwitchEpoch.value;
    docsRoot = await installTestPathProvider('p4e-gems-');
  });

  tearDown(() {
    final epoch = UserLocalDataIsolation.accountSwitchEpoch;
    if (epoch.value != savedEpoch) epoch.value = savedEpoch;
    if (docsRoot.existsSync()) docsRoot.deleteSync(recursive: true);
  });

  test('held cache write cannot survive owner B', () async {
    final storage = _HoldRemove();
    final isolation = UserLocalDataIsolation(
      storage,
      secureStorage: InMemorySecureStorage(),
    );
    expect((await isolation.onSignedIn('owner-a')).success, isTrue);
    var live = 'owner-a';
    final service = GemWalletService(
      GemWalletStore(storage),
      ownerId: 'owner-a',
      requireOwner: true,
      currentOwnerId: () => live,
    );
    storage.arm();
    final pending = service.acceptAuthoritativeBalance(77);
    await _until(() => storage.holding);
    final switchFuture = isolation.onSignedIn('owner-b');
    await _until(() => UserLocalDataIsolation.queuedOwnerMutations > 0);
    expect(isolation.localOwnerId, 'owner-a');
    live = 'owner-b';
    storage.release();
    await expectLater(pending, throwsA(isA<GemSpendException>()));
    expect((await switchFuture).success, isTrue);
    expect(isolation.localOwnerId, 'owner-b');
    expect(storage.getInt(GemWalletStore.serverBalanceCacheKey), isNull);
    expect(
      storage.getString(GemWalletStore.serverBalanceOwnerKey),
      isNot('owner-a'),
    );
    expect(GemWalletStore(storage).balanceForOwner('owner-b'), isNull);
  });

  test('disposed gem controller cannot republish A history', () async {
    final storage = LocalStorage.ephemeral();
    final store = GemWalletStore(storage);
    await store.write(
      balance: 12,
      transaction: GemTransaction(
        id: 'a-line',
        createdAt: DateTime.utc(2026, 9, 1),
        amount: 12,
        reason: 'A-ONLY-HISTORY',
        type: GemTransactionType.earned,
      ),
    );
    var live = 'owner-a';
    final stale = GemWalletController(
      GemWalletService(
        store,
        ownerId: 'owner-a',
        requireOwner: true,
        currentOwnerId: () => live,
      ),
    );
    expect(stale.history.single.reason, 'A-ONLY-HISTORY');
    var notified = 0;
    stale.addListener(() => notified++);
    stale.dispose();
    live = 'owner-b';
    await storage.remove(GemWalletStore.txKey);
    await stale.reload();
    expect(notified, 0);
    final next = GemWalletController(
      GemWalletService(
        GemWalletStore(storage),
        ownerId: 'owner-b',
        requireOwner: true,
        currentOwnerId: () => live,
      ),
    );
    expect(next.history, isEmpty);
  });

  testWidgets('mounted gems history drops A after provider recreation', (
    tester,
  ) async {
    OraclyL10n.bind('tr');
    final storage = LocalStorage.ephemeral();
    await GemWalletStore(storage).write(
      balance: 9,
      transaction: GemTransaction(
        id: 'a-line',
        createdAt: DateTime.utc(2026, 9, 1),
        amount: 9,
        reason: 'A-ONLY-HISTORY',
        type: GemTransactionType.earned,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        gemWalletProvider.overrideWith((ref) {
          ref.watch(_historyEpoch);
          return GemWalletController(GemWalletService(GemWalletStore(storage)));
        }),
      ],
    );
    addTearDown(container.dispose);
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: GemsHistoryCard())),
      ),
    );
    await tester.pump();
    expect(find.textContaining('A-ONLY-HISTORY'), findsOneWidget);
    await storage.remove(GemWalletStore.txKey);
    container.read(_historyEpoch.notifier).state++;
    await tester.pump();
    expect(find.textContaining('A-ONLY-HISTORY'), findsNothing);
    expect(find.text(GemsCopy.historyEmpty), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _until(bool Function() ready) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (!ready()) {
    if (DateTime.now().isAfter(deadline)) fail('condition was not reached');
    await Future<void>.delayed(Duration.zero);
  }
}

class _HoldRemove extends LocalStorage {
  _HoldRemove() : super.ephemeral();

  bool _armed = false;
  bool holding = false;
  Completer<void>? _hold;

  void arm() => _armed = true;

  void release() {
    final hold = _hold;
    if (hold != null && !hold.isCompleted) hold.complete();
  }

  @override
  Future<bool> remove(String key) async {
    if (_armed &&
        _hold == null &&
        key == GemWalletStore.serverBalanceCacheKey) {
      _hold = Completer<void>();
      holding = true;
      await _hold!.future;
    }
    return super.remove(key);
  }
}
