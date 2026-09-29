/// P4D.2 — profile rename and account switch share one critical section.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';

import '../../support/test_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late int savedEpoch;
  late Directory docsRoot;

  setUp(() async {
    savedEpoch = UserLocalDataIsolation.accountSwitchEpoch.value;
    docsRoot = await installTestPathProvider('p4d2-');
  });

  tearDown(() {
    final epoch = UserLocalDataIsolation.accountSwitchEpoch;
    if (epoch.value != savedEpoch) epoch.value = savedEpoch;
    if (docsRoot.existsSync()) docsRoot.deleteSync(recursive: true);
  });

  test(
    'rename-first: a pre-mutation profile_name write cannot enter B',
    () async {
      final storage = _HoldBeforeMutation();
      final isolation = _isolation(storage);
      expect((await isolation.onSignedIn('owner-a')).success, isTrue);
      await storage.setString('profile_name', 'A-NAME');
      await storage.setString('user_name', 'A-NAME');
      await storage.setString('profile_job', 'A-JOB');
      storage.holdKey = 'profile_name';

      final pending = _rename(storage, 'A-RENAMED', savedEpoch);
      await _until(
        () => storage.holding && storage.getString('profile_name') == 'A-NAME',
      );

      final switchFuture = isolation.onSignedIn('owner-b');
      await _until(
        () =>
            UserLocalDataIsolation.queuedOwnerMutations > 0 ||
            isolation.localOwnerId == 'owner-b',
      );
      expect(isolation.localOwnerId, 'owner-a');
      expect(UserLocalDataIsolation.queuedOwnerMutations, greaterThan(0));

      storage.release();
      await pending;
      final switched = await switchFuture;
      expect(switched.success, isTrue);
      expect(isolation.localOwnerId, 'owner-b');
      expect(storage.getString('profile_name'), isNot('A-RENAMED'));
      expect(storage.getString('user_name'), isNot('A-RENAMED'));
      expect(storage.getString('profile_job'), isNull);
    },
  );

  test('a pre-mutation user_name write cannot land after B commits', () async {
    final storage = _HoldBeforeMutation();
    final isolation = _isolation(storage);
    expect((await isolation.onSignedIn('owner-a')).success, isTrue);
    await storage.setString('profile_name', 'A-NAME');
    await storage.setString('user_name', 'A-NAME');
    storage.holdKey = 'user_name';

    final pending = _rename(storage, 'A-RENAMED', savedEpoch);
    await _until(
      () => storage.holding && storage.getString('user_name') == 'A-NAME',
    );
    expect(storage.getString('profile_name'), 'A-RENAMED');

    final switchFuture = isolation.onSignedIn('owner-b');
    await _until(
      () =>
          UserLocalDataIsolation.queuedOwnerMutations > 0 ||
          isolation.localOwnerId == 'owner-b',
    );
    expect(isolation.localOwnerId, 'owner-a');
    expect(UserLocalDataIsolation.queuedOwnerMutations, greaterThan(0));

    storage.release();
    await pending;
    expect((await switchFuture).success, isTrue);
    expect(storage.getString('user_name'), isNot('A-RENAMED'));
    expect(storage.getString('profile_name'), isNot('A-RENAMED'));
    expect(isolation.localOwnerId, 'owner-b');
  });

  test('switch-first: a queued rename performs no name writes', () async {
    final storage = _HoldOwnerCommit();
    final isolation = _isolation(storage);
    expect((await isolation.onSignedIn('owner-a')).success, isTrue);
    await storage.setString('profile_name', 'A-NAME');
    await storage.setString('user_name', 'A-NAME');
    await storage.setString('profile_job', 'A-JOB');
    storage.arm();

    final switchFuture = isolation.onSignedIn('owner-b');
    await _until(() => storage.holding);
    expect(isolation.localOwnerId, 'owner-a');
    final namesAtGate = storage.nameWrites;

    final pending = _rename(storage, 'A-RENAMED', savedEpoch);
    await _until(() => UserLocalDataIsolation.queuedOwnerMutations > 0);
    expect(storage.nameWrites, namesAtGate);
    expect(storage.getString('profile_name'), isNot('A-RENAMED'));

    storage.release();
    expect((await switchFuture).success, isTrue);
    await pending;
    expect(isolation.localOwnerId, 'owner-b');
    expect(storage.nameWrites, namesAtGate);
    expect(storage.getString('profile_name'), isNot('A-RENAMED'));
    expect(storage.getString('user_name'), isNot('A-RENAMED'));
    expect(storage.getString('profile_job'), isNull);
  });

  test('owner B keeps a legitimate same display name', () async {
    final storage = _HoldOwnerCommit();
    final isolation = _isolation(storage);
    expect((await isolation.onSignedIn('owner-a')).success, isTrue);
    await storage.setString('profile_name', 'A-NAME');
    storage.arm();

    final switchFuture = isolation.onSignedIn('owner-b');
    await _until(() => storage.holding);
    await storage.setString('profile_name', 'Alex');
    await storage.setString('user_name', 'Alex');
    final namesAtGate = storage.nameWrites;

    final pending = _rename(storage, 'Alex', savedEpoch);
    await _until(() => UserLocalDataIsolation.queuedOwnerMutations > 0);
    expect(storage.nameWrites, namesAtGate);

    storage.release();
    expect((await switchFuture).success, isTrue);
    await pending;
    expect(storage.getString('profile_name'), 'Alex');
    expect(storage.getString('user_name'), 'Alex');
    expect(storage.nameWrites, namesAtGate);
    expect(isolation.localOwnerId, 'owner-b');
  });
}

UserLocalDataIsolation _isolation(LocalStorage storage) {
  return UserLocalDataIsolation(
    storage,
    secureStorage: InMemorySecureStorage(),
  );
}

Future<void> _rename(_HoldBeforeMutation storage, String name, int epoch) {
  return MockUserRepository(storage).renameDisplayName(
    name,
    stillOwner: () => UserLocalDataIsolation.accountSwitchEpoch.value == epoch,
  );
}

Future<void> _until(bool Function() ready) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (!ready()) {
    if (DateTime.now().isAfter(deadline)) fail('condition was not reached');
    await Future<void>.delayed(Duration.zero);
  }
}

class _HoldBeforeMutation extends LocalStorage {
  _HoldBeforeMutation() : super.ephemeral();

  String? holdKey;
  bool holding = false;
  Completer<void>? _hold;
  int nameWrites = 0;

  void release() {
    final hold = _hold;
    if (hold != null && !hold.isCompleted) hold.complete();
  }

  @override
  Future<bool> setString(String key, String value) async {
    if (key == 'profile_name' || key == 'user_name') nameWrites++;
    if (key == holdKey && _hold == null) {
      _hold = Completer<void>();
      holding = true;
      await _hold!.future;
    }
    return _commit(key, value);
  }

  Future<bool> _commit(String key, String value) => super.setString(key, value);
}

class _HoldOwnerCommit extends _HoldBeforeMutation {
  bool _armed = false;
  bool _used = false;

  void arm() => _armed = true;

  @override
  Future<bool> setString(String key, String value) async {
    if (key == 'profile_name' || key == 'user_name') nameWrites++;
    if (_armed &&
        !_used &&
        key == UserLocalDataIsolation.ownerKey &&
        value == 'owner-b') {
      _used = true;
      _hold = Completer<void>();
      holding = true;
      await _hold!.future;
    }
    return _commit(key, value);
  }
}
