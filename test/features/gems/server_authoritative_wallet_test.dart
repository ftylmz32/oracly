import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/gems/controllers/gem_wallet_controller.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_gateway.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:oracly_new/features/gems/widgets/oracly_live_gem_capsule.dart';
import 'package:oracly_new/features/gems/providers/gem_providers.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_gateway.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'server snapshot overrides legacy balance and survives offline',
    () async {
      final storage = LocalStorage.ephemeral({
        GemWalletStore.balanceKey: 999999,
        GemWalletStore.serverBalanceCacheKey: 35,
      });
      var online = false;
      final service = GemWalletService(
        GemWalletStore(storage),
        gateway: GemWalletGateway((method, path, body) async {
          if (!online) return null;
          return const ReadingOperationWire(
            statusCode: 200,
            json: {
              'data': {'balance': 12},
            },
          );
        }),
      );

      expect(service.balance, 35);
      expect(service.stale, isTrue);
      expect(await service.refresh(), isNull);
      expect(service.balance, 35);
      expect(service.stale, isTrue);

      online = true;
      expect(await service.refresh(), 12);
      expect(service.balance, 12);
      expect(service.stale, isFalse);
      expect(storage.getInt(GemWalletStore.balanceKey), 999999);
    },
  );

  test('no owner cache stays non-numeric until auth-ready hydration', () async {
    final storage = LocalStorage.ephemeral();
    final early = GemWalletController(
      GemWalletService(GemWalletStore(storage), requireOwner: true),
    );

    expect(early.displayBalance, isNull);
    expect(early.formatted, '—');
    expect(early.hydrationState, GemWalletHydrationState.loading);
    await early.reload();
    expect(early.displayBalance, isNull);

    var gets = 0;
    final ready = GemWalletController(
      GemWalletService(
        GemWalletStore(storage),
        ownerId: 'uid-a',
        requireOwner: true,
        gateway: GemWalletGateway((method, path, body) async {
          gets += 1;
          expect(method, 'GET');
          expect(path, '/v1/gems/balance');
          return const ReadingOperationWire(
            statusCode: 200,
            json: {
              'data': {'balance': 95},
            },
          );
        }),
      ),
    );
    await GemWalletHydrationCoordinator().hydrate('uid-a', ready);

    expect(gets, 1);
    expect(ready.balance, 95);
    expect(ready.authoritative, isTrue);
  });

  testWidgets('Gem capsule never labels missing cache as zero Gems', (
    tester,
  ) async {
    final controller = GemWalletController(
      GemWalletService(
        GemWalletStore(LocalStorage.ephemeral()),
        requireOwner: true,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [gemWalletProvider.overrideWith((ref) => controller)],
        child: const MaterialApp(
          home: Scaffold(body: OraclyLiveGemCapsule(interactive: false)),
        ),
      ),
    );

    expect(find.text('—'), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });

  test(
    'owner-bound 95 remains visible stale until authoritative refresh',
    () async {
      final storage = LocalStorage.ephemeral({
        GemWalletStore.serverBalanceOwnerKey: 'uid-a',
        GemWalletStore.serverBalanceCacheKey: 95,
      });
      final controller = GemWalletController(
        GemWalletService(
          GemWalletStore(storage),
          ownerId: 'uid-a',
          requireOwner: true,
          gateway: GemWalletGateway(
            (method, path, body) async => const ReadingOperationWire(
              statusCode: 200,
              json: {
                'data': {'balance': 95},
              },
            ),
          ),
        ),
      );

      expect(controller.balance, 95);
      expect(controller.hydrationState, GemWalletHydrationState.stale);
      await GemWalletHydrationCoordinator().hydrate('uid-a', controller);
      expect(controller.balance, 95);
      expect(controller.authoritative, isTrue);
    },
  );

  test('failed auth-ready GET preserves cache and remains retryable', () async {
    final storage = LocalStorage.ephemeral({
      GemWalletStore.serverBalanceOwnerKey: 'uid-a',
      GemWalletStore.serverBalanceCacheKey: 95,
    });
    var succeeds = false;
    var gets = 0;
    final controller = GemWalletController(
      GemWalletService(
        GemWalletStore(storage),
        ownerId: 'uid-a',
        requireOwner: true,
        gateway: GemWalletGateway((method, path, body) async {
          gets += 1;
          if (!succeeds) return null;
          return const ReadingOperationWire(
            statusCode: 200,
            json: {
              'data': {'balance': 94},
            },
          );
        }),
      ),
    );
    final coordinator = GemWalletHydrationCoordinator();

    await coordinator.hydrate('uid-a', controller);
    expect(controller.balance, 95);
    expect(controller.hydrationState, GemWalletHydrationState.error);
    succeeds = true;
    await coordinator.hydrate('uid-a', controller);
    expect(gets, 2);
    expect(controller.balance, 94);
    expect(controller.authoritative, isTrue);
  });

  test(
    'owner switch while balance GET is in flight cannot publish or cache the old owner response',
    () async {
      final storage = LocalStorage.ephemeral();
      final response = Completer<ReadingOperationWire?>();
      var liveOwner = 'uid-a';
      final store = GemWalletStore(storage);
      final service = GemWalletService(
        store,
        ownerId: 'uid-a',
        requireOwner: true,
        currentOwnerId: () => liveOwner,
        gateway: GemWalletGateway((method, path, body) {
          expect(method, 'GET');
          expect(path, '/v1/gems/balance');
          return response.future;
        }),
      );
      final controller = GemWalletController(service);

      final pending = controller.reload();
      liveOwner = 'uid-b';
      response.complete(
        const ReadingOperationWire(
          statusCode: 200,
          json: {
            'data': {'balance': 95},
          },
        ),
      );
      await pending;

      expect(controller.authoritative, isFalse);
      expect(controller.displayBalance, isNull);
      expect(service.stale, isTrue);
      expect(store.balanceForOwner('uid-a'), isNull);
    },
  );

  test('account switch never exposes the previous owner balance', () async {
    final storage = LocalStorage.ephemeral({
      GemWalletStore.serverBalanceOwnerKey: 'uid-a',
      GemWalletStore.serverBalanceCacheKey: 95,
    });
    final switched = GemWalletController(
      GemWalletService(
        GemWalletStore(storage),
        ownerId: 'uid-b',
        requireOwner: true,
      ),
    );

    expect(switched.displayBalance, isNull);
    expect(switched.formatted, '—');
    expect(switched.hydrationState, GemWalletHydrationState.loading);
  });

  test('provider recreation joins one GET and receives its result', () async {
    final storage = LocalStorage.ephemeral();
    final response = Completer<ReadingOperationWire?>();
    var gets = 0;
    GemWalletController controller() => GemWalletController(
      GemWalletService(
        GemWalletStore(storage),
        ownerId: 'uid-a',
        requireOwner: true,
        gateway: GemWalletGateway((method, path, body) {
          gets += 1;
          return response.future;
        }),
      ),
    );
    final first = controller();
    final recreated = controller();
    final coordinator = GemWalletHydrationCoordinator();

    final one = coordinator.hydrate('uid-a', first);
    final two = coordinator.hydrate('uid-a', recreated);
    response.complete(
      const ReadingOperationWire(
        statusCode: 200,
        json: {
          'data': {'balance': 95},
        },
      ),
    );
    await Future.wait([one, two]);

    expect(gets, 1);
    expect(recreated.balance, 95);
    expect(recreated.authoritative, isTrue);
  });

  test('controller refresh publishes authoritative balance to UI', () async {
    final service = GemWalletService(
      GemWalletStore(LocalStorage.ephemeral()),
      gateway: GemWalletGateway(
        (method, path, body) async => const ReadingOperationWire(
          statusCode: 200,
          json: {
            'data': {'balance': 28},
          },
        ),
      ),
    );
    final controller = GemWalletController(service);
    var notifications = 0;
    controller.addListener(() => notifications += 1);

    await controller.reload();

    expect(controller.balance, 28);
    expect(controller.stale, isFalse);
    expect(notifications, greaterThanOrEqualTo(2));
  });

  test('busy wallet rejects overlapping mutation command', () async {
    final service = GemWalletService(
      GemWalletStore(LocalStorage.ephemeral()),
      gateway: GemWalletGateway((method, path, body) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return const ReadingOperationWire(
          statusCode: 200,
          json: {
            'data': {'balance': 20, 'granted': true},
          },
        );
      }),
    );
    final first = service.claimStarter(idempotencyKey: 'starter-client-01');

    await expectLater(
      service.claimStarter(idempotencyKey: 'starter-client-01'),
      throwsA(isA<GemSpendException>()),
    );
    expect((await first)?.balance, 20);
  });

  test('purpose commands accept only returned server balances', () async {
    final calls = <String>[];
    final service = GemWalletService(
      GemWalletStore(LocalStorage.ephemeral()),
      gateway: GemWalletGateway((method, path, body) async {
        calls.add(path);
        final balance = switch (path) {
          '/v1/gems/starter-grant' => 20,
          '/v1/gems/daily-reward' => 70,
          _ => 50,
        };
        return ReadingOperationWire(
          statusCode: 200,
          json: {
            'data': {
              'balance': balance,
              'granted': !path.contains('tarot'),
              'settled': path.contains('tarot'),
              'canonicalCost': path.contains('tarot') ? 20 : null,
              'serverDay': path.contains('daily') ? '2026-09-09' : null,
            },
          },
        );
      }),
    );

    await service.claimStarter(idempotencyKey: 'starter-client-01');
    expect(service.balance, 20);
    await service.claimDaily(idempotencyKey: 'daily-client-01');
    expect(service.balance, 70);
    final settled = await service.settleTarot(
      operationId: 'paid-tarot-session-01',
      idempotencyKey: 'paid-tarot-session-01',
    );
    expect(settled?.canonicalCost, 20);
    expect(service.balance, 50);
    expect(
      calls,
      containsAll(<String>[
        '/v1/gems/starter-grant',
        '/v1/gems/daily-reward',
        '/v1/gems/tarot/paid-tarot-session-01/settle',
      ]),
    );
  });

  test(
    'local earn and spend cannot mutate either cache or legacy balance',
    () async {
      final storage = LocalStorage.ephemeral({
        GemWalletStore.serverBalanceCacheKey: 40,
        GemWalletStore.balanceKey: 9000,
      });
      final service = GemWalletService(GemWalletStore(storage));

      await expectLater(
        service.earn(amount: 999999, reason: 'tamper'),
        throwsA(isA<GemSpendException>()),
      );
      await expectLater(
        service.spend(amount: 1, reason: 'tamper'),
        throwsA(isA<GemSpendException>()),
      );
      expect(service.balance, 40);
      expect(storage.getInt(GemWalletStore.balanceKey), 9000);
    },
  );
}
