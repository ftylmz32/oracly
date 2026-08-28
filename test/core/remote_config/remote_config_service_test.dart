import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/remote_config/remote_config_activation.dart';
import 'package:oracly_new/core/remote_config/remote_config_defaults.dart';
import 'package:oracly_new/core/remote_config/remote_config_pending_store.dart';
import 'package:oracly_new/core/remote_config/remote_config_port.dart';
import 'package:oracly_new/core/remote_config/remote_config_runtime.dart';
import 'package:oracly_new/core/remote_config/remote_config_service.dart';
import 'package:oracly_new/core/remote_config/remote_config_validation.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('RemoteConfigService', () {
    test('failed fetch keeps defaults without staging', () async {
      final service = RemoteConfigService(port: _FailingPort());
      expect(service.snapshot, RemoteConfigDefaults.snapshot);
      final result = await service.refresh();
      expect(result.kind, RemoteConfigValidationKind.missing);
      expect(service.snapshot, RemoteConfigDefaults.snapshot);
      expect(service.hasPending, isFalse);
      expect(RemoteConfigRuntime.snapshot, RemoteConfigDefaults.snapshot);
    });

    test('validated remote is staged — live UI stays on current session',
        () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final service = RemoteConfigService(
        port: _StaticPort({
          'config_version': 3,
          'gem_history_display_limit': 5,
        }),
        pendingStore: RemoteConfigPendingStore(storage),
      );
      final before = service.snapshot.gemHistoryDisplayLimit;
      await service.refresh(activation: RemoteConfigActivation.nextSession);
      expect(service.snapshot.gemHistoryDisplayLimit, before);
      expect(RemoteConfigRuntime.snapshot.gemHistoryDisplayLimit, before);
      expect(service.hasPending, isTrue);
      expect(service.pending!.gemHistoryDisplayLimit, 5);
    });

    test('session boundary / beginSession activates staged config', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final port = _StaticPort({
        'config_version': 3,
        'gem_history_display_limit': 5,
      });
      final first = RemoteConfigService(
        port: port,
        pendingStore: RemoteConfigPendingStore(storage),
      );
      await first.refresh(activation: RemoteConfigActivation.nextSession);
      expect(first.snapshot.gemHistoryDisplayLimit,
          RemoteConfigDefaults.snapshot.gemHistoryDisplayLimit);

      final next = RemoteConfigService(
        port: port,
        pendingStore: RemoteConfigPendingStore(storage),
      );
      await next.beginSession();
      expect(next.snapshot.gemHistoryDisplayLimit, 5);
      expect(RemoteConfigRuntime.snapshot.gemHistoryDisplayLimit, 5);
    });

    test('controlled refresh activates without waiting for next cold start',
        () async {
      final service = RemoteConfigService(
        port: _StaticPort({
          'config_version': 4,
          'gem_history_display_limit': 6,
        }),
      );
      await service.controlledRefresh();
      expect(service.snapshot.gemHistoryDisplayLimit, 6);
      expect(service.hasPending, isFalse);
    });
  });
}

class _FailingPort implements RemoteConfigPort {
  @override
  Future<Map<String, Object?>?> fetch() async => throw StateError('offline');
}

class _StaticPort implements RemoteConfigPort {
  _StaticPort(this._payload);

  final Map<String, Object?> _payload;

  @override
  Future<Map<String, Object?>?> fetch() async => _payload;
}
