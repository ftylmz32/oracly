/// Wallet owner-bootstrap lifecycle races, driven through the real
/// [gemWalletProvider] / [gemWalletServiceProvider] / firebaseAuthUserProvider
/// graph. Only the edges are faked: the Firebase auth gateway, the shared
/// authenticated sender, and the Firebase/App Check readiness chain (paused
/// via [GemWalletBootstrap.debugEnsureReadyOverride]).
///
/// Regression for iOS Build 6: after a cold start the shared sender worked
/// (push-token registration returned 200) yet the wallet never issued
/// GET /v1/gems/balance and stayed at "—".
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/account_deletion_pending_state.dart';
import 'package:oracly_new/core/auth/firebase/firebase_auth_gateway.dart';
import 'package:oracly_new/core/auth/firebase/firebase_auth_user.dart';
import 'package:oracly_new/core/auth/mock_auth_service.dart';
import 'package:oracly_new/core/auth/token_manager.dart';
import 'package:oracly_new/core/config/app_environment.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/providers/backend_providers.dart' as backend;
import 'package:oracly_new/features/ai/production/ai_runtime_config.dart';
import 'package:oracly_new/features/ai/production/oracly_ai_providers.dart';
import 'package:oracly_new/features/gems/controllers/gem_wallet_controller.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/gems/providers/gem_providers.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_bootstrap.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_gateway.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_owner_bootstrap.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:oracly_new/features/reading_operation/providers/reading_live_provider.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_gateway.dart';

const _prod = AiRuntimeConfig(
  environment: AppEnvironment.production,
  proxyUrl: 'https://api.oracly.app/v1/ai/complete',
);

/// Firebase restores `currentUser` (keychain) before `authStateChanges`
/// delivers its first event — the cold-start shape that rebuilds the wallet
/// provider graph for the SAME uid.
class _Gateway implements FirebaseAuthGateway {
  final _events = StreamController<FirebaseAuthUserSnapshot?>.broadcast();
  FirebaseAuthUserSnapshot? _user;

  void restore(String uid) =>
      _user = FirebaseAuthUserSnapshot(uid: uid, isAnonymous: true);

  void emitCurrent() => _events.add(_user);

  void switchTo(String uid) {
    restore(uid);
    emitCurrent();
  }

  @override
  bool get isInitialized => true;

  @override
  FirebaseAuthUserSnapshot? get currentUser => _user;

  @override
  Stream<FirebaseAuthUserSnapshot?> authStateChanges() => _events.stream;

  @override
  Future<String?> currentIdToken({bool forceRefresh = false}) async =>
      _user == null ? null : 'id-token';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Tokens implements TokenManager {
  @override
  Future<String?> getAccessToken({bool forceRefresh = false}) async =>
      'id-token';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Shared authenticated sender. Records every balance GET with the live
/// owner it was sent for, and the peak number of concurrent GETs.
class _Server {
  _Server(this.gateway, this.balances);
  final _Gateway gateway;
  final Map<String, int> balances;
  final List<String> balanceGets = [];
  int _active = 0;
  int peakConcurrentGets = 0;

  Future<ReadingOperationWire?> send(
    String method,
    String path,
    Map<String, Object>? body,
  ) async {
    if (method != 'GET' || path != '/v1/gems/balance') return null;
    final owner = gateway.currentUser!.uid;
    balanceGets.add(owner);
    _active += 1;
    if (_active > peakConcurrentGets) peakConcurrentGets = _active;
    await Future<void>.delayed(Duration.zero);
    _active -= 1;
    return ReadingOperationWire(
      statusCode: 200,
      json: {
        'data': {'balance': balances[owner]},
      },
    );
  }
}

/// Readiness gate: the first call can be held open; each call is counted and
/// overlap between calls is recorded.
class _Readiness {
  final Completer<bool> firstGate = Completer<bool>();
  bool holdFirst = true;
  int calls = 0;
  int _active = 0;
  int peakConcurrent = 0;
  final List<bool> scripted = [];

  Future<bool> call() async {
    calls += 1;
    _active += 1;
    if (_active > peakConcurrent) peakConcurrent = _active;
    try {
      if (calls == 1 && holdFirst) return await firstGate.future;
      return scripted.isNotEmpty ? scripted.removeAt(0) : true;
    } finally {
      _active -= 1;
    }
  }
}

Future<void> _settle() async {
  for (var i = 0; i < 30; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late _Gateway gateway;
  late _Server server;
  late _Readiness readiness;
  late LocalStorage storage;
  late ProviderContainer container;
  ProviderSubscription<GemWalletController>? keepAlive;

  setUp(() {
    AccountDeletionPendingState.markClear();
    gateway = _Gateway();
    server = _Server(gateway, {'uid-a': 7, 'uid-b': 30});
    readiness = _Readiness();
    storage = LocalStorage.ephemeral();
    GemWalletBootstrap.debugEnsureReadyOverride = readiness.call;
    container = ProviderContainer(
      overrides: [
        backend.localStorageProvider.overrideWithValue(storage),
        backend.firebaseAuthGatewayProvider.overrideWithValue(gateway),
        backend.authServiceProvider.overrideWithValue(MockAuthService()),
        backend.tokenManagerProvider.overrideWithValue(_Tokens()),
        aiRuntimeConfigProvider.overrideWithValue(_prod),
        readingOperationSenderProvider.overrideWithValue(server.send),
      ],
    );
  });

  tearDown(() {
    keepAlive?.close();
    keepAlive = null;
    container.dispose();
    GemWalletBootstrap.debugEnsureReadyOverride = null;
  });

  /// Cold start: provider A is built from the restored `currentUser` and its
  /// owner bootstrap blocks inside readiness; the first auth event then
  /// rebuilds the graph into provider B.
  Future<(GemWalletController, GemWalletController)> coldStartRebuild({
    String emitAs = 'uid-a',
  }) async {
    gateway.restore('uid-a');
    keepAlive = container.listen(gemWalletProvider, (_, _) {});
    final a = container.read(gemWalletProvider);
    await _settle();
    expect(a.ownerId, 'uid-a');
    expect(readiness.calls, 1, reason: 'A owns the bootstrap and is paused');

    if (emitAs == 'uid-a') {
      gateway.emitCurrent();
    } else {
      gateway.switchTo(emitAs);
    }
    await _settle();
    final b = container.read(gemWalletProvider);
    await _settle();
    expect(identical(a, b), isFalse, reason: 'auth event rebuilt the wallet');
    return (a, b);
  }

  test('same-owner rebuild while bootstrap is in flight still hydrates the '
      'current wallet (iOS Build 6 lost wakeup)', () async {
    final (a, b) = await coldStartRebuild();
    expect(b.ownerId, 'uid-a');

    // Predecessor A finishes readiness after it has been replaced.
    readiness.firstGate.complete(true);
    await _settle();

    expect(server.balanceGets, [
      'uid-a',
    ], reason: 'current wallet must issue GET /v1/gems/balance');
    expect(b.authoritative, isTrue);
    expect(b.formatted, '7');
    // The replaced provider stays dead.
    expect(a.authoritative, isFalse);
    expect(a.formatted, '—');
  });

  test(
    'bootstraps for one owner never overlap and GETs never run concurrently',
    () async {
      await coldStartRebuild();
      readiness.firstGate.complete(true);
      await _settle();

      expect(readiness.peakConcurrent, 1);
      expect(server.peakConcurrentGets, 1);
      expect(server.balanceGets.length, 1);
    },
  );

  test(
    'owner switch during an in-flight bootstrap stays fail-closed',
    () async {
      final (a, b) = await coldStartRebuild(emitAs: 'uid-b');
      expect(b.ownerId, 'uid-b');
      await _settle();

      readiness.firstGate.complete(true);
      await _settle();

      expect(
        server.balanceGets,
        everyElement('uid-b'),
        reason: 'no request may be sent for the replaced owner',
      );
      expect(b.authoritative, isTrue);
      expect(b.formatted, '30');
      expect(a.authoritative, isFalse);
      final store = GemWalletStore(storage);
      expect(
        store.balanceForOwner('uid-a'),
        isNull,
        reason: 'the new owner never consumes or writes A state',
      );
      expect(store.balanceForOwner('uid-b'), 30);
    },
  );

  testWidgets('transient transport-not-ready still retries on its timer', (
    tester,
  ) async {
    readiness
      ..holdFirst = false
      ..scripted.add(false);
    gateway.restore('uid-a');
    keepAlive = container.listen(gemWalletProvider, (_, _) {});
    final wallet = container.read(gemWalletProvider);
    await tester.pump();
    await tester.pump();

    expect(readiness.calls, 1);
    expect(server.balanceGets, isEmpty);
    expect(wallet.formatted, '—');

    await tester.pump(const Duration(seconds: 13));
    for (var i = 0; i < 10; i++) {
      await tester.pump();
    }

    expect(readiness.calls, 2);
    expect(server.balanceGets, ['uid-a']);
    expect(wallet.authoritative, isTrue);
    expect(wallet.formatted, '7');
  });

  test(
    'predecessor that fails readiness does not strand the current wallet',
    () async {
      final (_, b) = await coldStartRebuild();
      readiness.firstGate.complete(false);
      await _settle();

      expect(server.balanceGets, ['uid-a']);
      expect(b.authoritative, isTrue);
    },
  );

  test('current bootstrap survives more than three same-owner lock turnovers '
      'and still hydrates (no join-count liveness hole)', () async {
    const turnovers = 5;
    final coordinator = container.read(gemWalletHydrationCoordinatorProvider);
    final wallet = GemWalletService(
      GemWalletStore(storage),
      ownerId: 'uid-a',
      requireOwner: true,
      gateway: GemWalletGateway(server.send),
    );
    final current = GemWalletController(wallet);
    gateway.restore('uid-a');
    readiness.holdFirst = false;

    // A same-owner contender already holds the lock.
    expect(coordinator.beginBootstrap('uid-a'), isTrue);
    final outcome = bootstrapGemWalletOwner(
      ownerId: 'uid-a',
      controller: current,
      wallet: wallet,
      coordinator: coordinator,
      config: _prod,
      auth: MockAuthService(),
      accessToken: _Tokens().getAccessToken,
      ensureStarter: () async {},
      isOwnerCurrent: () => true,
    );

    // Each holder releases and a new same-owner contender claims in the
    // same synchronous turn, so the waiter always observes the release
    // but finds the lock re-taken when its continuation runs.
    for (var i = 0; i < turnovers; i++) {
      await _settle();
      expect(readiness.calls, 0, reason: 'no work while the lock is held');
      expect(server.balanceGets, isEmpty);
      coordinator.endBootstrap('uid-a');
      expect(coordinator.beginBootstrap('uid-a'), isTrue);
    }
    await _settle();
    coordinator.endBootstrap('uid-a');

    final result = await outcome;
    await _settle();
    expect(
      result,
      GemWalletOwnerBootstrapOutcome.completed,
      reason:
          'balanceGets=${server.balanceGets.length} '
          'authoritative=${current.authoritative} '
          'formatted=${current.formatted}',
    );
    expect(readiness.calls, 1);
    expect(readiness.peakConcurrent, 1);
    expect(server.balanceGets, ['uid-a']);
    expect(server.peakConcurrentGets, 1);
    expect(current.authoritative, isTrue);
    expect(current.formatted, '7');
  });
}
