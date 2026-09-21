/// Cold-start gem hydration + affordability regressions.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/gems/controllers/gem_wallet_controller.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/gems/services/gem_starter_grant.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_gateway.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_hydration.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_gateway.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/false_return_local_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('auth-late then ready hydrates exact balance including zero', () async {
    final storage = LocalStorage.ephemeral();
    var online = false;
    var gets = 0;
    GemWalletGateway gateway() => GemWalletGateway((method, path, body) async {
          if (!online) return null;
          gets += 1;
          expect(path, '/v1/gems/balance');
          return const ReadingOperationWire(
            statusCode: 200,
            json: {
              'data': {'balance': 0},
            },
          );
        });

    final early = GemWalletController(
      GemWalletService(GemWalletStore(storage), requireOwner: true),
    );
    expect(early.formatted, '—');
    expect(early.canSpend(1), isFalse);

    online = true;
    final ready = GemWalletController(
      GemWalletService(
        GemWalletStore(storage),
        ownerId: 'uid-a',
        requireOwner: true,
        gateway: gateway(),
      ),
    );
    await GemWalletHydrationCoordinator().hydrateWithRetry('uid-a', ready);
    expect(gets, greaterThan(0));
    expect(ready.formatted, '0');
    expect(ready.authoritative, isTrue);
    expect(ready.canSpend(1), isFalse);
  });

  test('transient transport failure then retry becomes authoritative', () async {
    final storage = LocalStorage.ephemeral();
    var failLeft = 2;
    final controller = GemWalletController(
      GemWalletService(
        GemWalletStore(storage),
        ownerId: 'uid-a',
        requireOwner: true,
        gateway: GemWalletGateway((method, path, body) async {
          if (failLeft > 0) {
            failLeft -= 1;
            return null;
          }
          return const ReadingOperationWire(
            statusCode: 200,
            json: {
              'data': {'balance': 42},
            },
          );
        }),
      ),
    );
    await GemWalletHydrationCoordinator().hydrateWithRetry(
      'uid-a',
      controller,
      attempts: 5,
    );
    expect(controller.balance, 42);
    expect(controller.formatted, '42');
    expect(controller.authoritative, isTrue);
  });

  test('owner-scoped cache does not leak across accounts', () async {
    final storage = LocalStorage.ephemeral();
    await GemWalletStore(storage).cacheServerBalance(77, ownerId: 'uid-a');
    final other = GemWalletService(
      GemWalletStore(storage),
      ownerId: 'uid-b',
      requireOwner: true,
    );
    expect(other.cachedBalance, isNull);
    expect(
      GemWalletController(other).formatted,
      '—',
    );
  });

  test(
    'owner switch fails closed when old balance removal returns false',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = FalseReturnLocalStorage(
        await SharedPreferences.getInstance(),
      );
      final store = GemWalletStore(storage);
      await store.cacheServerBalance(77, ownerId: 'uid-a');
      storage.falseReturnRemoveKeys.add(GemWalletStore.serverBalanceCacheKey);

      final controller = GemWalletController(
        GemWalletService(
          store,
          ownerId: 'uid-b',
          requireOwner: true,
          gateway: GemWalletGateway((method, path, body) async {
            return const ReadingOperationWire(
              statusCode: 200,
              json: {
                'data': {'balance': 42},
              },
            );
          }),
        ),
      );

      await controller.reload();

      expect(controller.authoritative, isFalse);
      expect(controller.hydrationState, GemWalletHydrationState.error);
      expect(store.balanceForOwner('uid-b'), isNull);
      expect(store.balanceForOwner('uid-a'), 77);
      expect(storage.getString(GemWalletStore.serverBalanceOwnerKey), 'uid-a');
    },
  );

  test(
    'owner switch never exposes old balance when new owner write fails',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = FalseReturnLocalStorage(
        await SharedPreferences.getInstance(),
      );
      final store = GemWalletStore(storage);
      await store.cacheServerBalance(77, ownerId: 'uid-a');
      storage.falseReturnKeys.add(GemWalletStore.serverBalanceOwnerKey);

      final controller = GemWalletController(
        GemWalletService(
          store,
          ownerId: 'uid-b',
          requireOwner: true,
          gateway: GemWalletGateway((method, path, body) async {
            return const ReadingOperationWire(
              statusCode: 200,
              json: {
                'data': {'balance': 42},
              },
            );
          }),
        ),
      );

      await controller.reload();

      expect(controller.authoritative, isFalse);
      expect(controller.hydrationState, GemWalletHydrationState.error);
      expect(store.balanceForOwner('uid-b'), isNull);
      expect(storage.getInt(GemWalletStore.serverBalanceCacheKey), isNull);
    },
  );

  test('gateway accepts numeric balance as num from JSON', () async {
    final storage = LocalStorage.ephemeral();
    final service = GemWalletService(
      GemWalletStore(storage),
      ownerId: 'uid-a',
      requireOwner: true,
      gateway: GemWalletGateway((method, path, body) async {
        return const ReadingOperationWire(
          statusCode: 200,
          json: {
            'data': {'balance': 12.0},
          },
        );
      }),
    );
    expect(await service.refresh(), 12);
  });

  test('starter grant transient null does not mark local completion', () async {
    final storage = LocalStorage.ephemeral();
    final grant = GemStarterGrant(
      GemWalletService(
        GemWalletStore(storage),
        ownerId: 'uid-a',
        requireOwner: true,
        gateway: GemWalletGateway((method, path, body) async => null),
      ),
      storage,
    );
    expect(await grant.ensureOnce(), isFalse);
    expect(storage.getBool(GemStarterGrant.flagKey), isNot(true));
    expect(grant.alreadyGranted, isFalse);
  });

  test('starter grant success caches authoritative balance', () async {
    final storage = LocalStorage.ephemeral();
    final service = GemWalletService(
      GemWalletStore(storage),
      ownerId: 'uid-a',
      requireOwner: true,
      gateway: GemWalletGateway((method, path, body) async {
        if (path.contains('starter-grant')) {
          return const ReadingOperationWire(
            statusCode: 200,
            json: {
              'data': {
                'balance': 20,
                'granted': true,
                'idempotent': false,
              },
            },
          );
        }
        return null;
      }),
    );
    final grant = GemStarterGrant(service, storage);
    expect(await grant.ensureOnce(), isTrue);
    expect(storage.getBool(GemStarterGrant.flagKey), isTrue);
    expect(service.cachedBalance, 20);
    expect(service.stale, isFalse);
  });

  test('paid affordability requires authoritative hydrated wallet', () async {
    final storage = LocalStorage.ephemeral();
    final loading = GemWalletController(
      GemWalletService(GemWalletStore(storage), requireOwner: true),
    );
    expect(loading.authoritative, isFalse);
    expect(loading.canSpend(20), isFalse);

    final rich = GemWalletController(
      GemWalletService(
        GemWalletStore(storage),
        ownerId: 'uid-a',
        requireOwner: true,
        gateway: GemWalletGateway((method, path, body) async {
          return const ReadingOperationWire(
            statusCode: 200,
            json: {
              'data': {'balance': 50},
            },
          );
        }),
      ),
    );
    await rich.reload();
    expect(rich.authoritative, isTrue);
    expect(rich.canSpend(20), isTrue);
    expect(rich.canSpend(80), isFalse);
  });
}
