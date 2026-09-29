/// P4D.1 — a held profile rename cannot write into the next owner.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/copy/resilience_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/screens/profile/reference/profile_reference_screen.dart';

import '../../support/test_path_provider.dart';
import '../../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late int savedEpoch;
  late Directory docsRoot;

  setUp(() async {
    OraclyL10n.bind('tr');
    savedEpoch = UserLocalDataIsolation.accountSwitchEpoch.value;
    docsRoot = await installTestPathProvider('p4d1-');
  });

  tearDown(() {
    final epoch = UserLocalDataIsolation.accountSwitchEpoch;
    if (epoch.value != savedEpoch) epoch.value = savedEpoch;
    if (docsRoot.existsSync()) docsRoot.deleteSync(recursive: true);
  });

  test('rename writes only the two name keys', () async {
    final storage = _ScriptedStorage();
    await _seedOwnerA(storage);
    final repo = MockUserRepository(storage);
    storage.writes.clear();
    await repo.renameDisplayName('NEW-NAME', stillOwner: () => true);
    expect(storage.getString('profile_name'), 'NEW-NAME');
    expect(storage.getString('user_name'), 'NEW-NAME');
    expect(storage.getString('profile_job'), 'A-JOB');
    expect(storage.getStringList('profile_interests'), ['A-INTEREST']);
    expect(storage.writes, ['profile_name', 'user_name']);
  });

  testWidgets('unchanged rename does not write', (tester) async {
    final storage = _ScriptedStorage();
    await storage.setString('profile_name', 'Ada');
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        overrides: [
          userRepositoryProvider.overrideWithValue(MockUserRepository(storage)),
        ],
        child: const MaterialApp(home: ProfileReferenceScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    storage.writes.clear();
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Kaydet'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(storage.writes, isEmpty);
    expect(storage.getString('profile_name'), 'Ada');
  });

  test('a false profile_name write does not touch user_name', () async {
    final storage = _ScriptedStorage();
    await storage.setString('profile_name', 'A-NAME');
    await storage.setString('user_name', 'A-NAME');
    storage.failNextProfileName = true;
    final repo = MockUserRepository(storage);
    await expectLater(
      repo.renameDisplayName('NEW-NAME', stillOwner: () => true),
      throwsStateError,
    );
    expect(storage.getString('profile_name'), 'A-NAME');
    expect(storage.getString('user_name'), 'A-NAME');
  });

  test('a false user_name write rolls the display name back', () async {
    final storage = _ScriptedStorage();
    await storage.setString('profile_name', 'A-NAME');
    await storage.setString('user_name', 'A-NAME');
    storage.failNextUserName = true;
    final repo = MockUserRepository(storage);
    await expectLater(
      repo.renameDisplayName('NEW-NAME', stillOwner: () => true),
      throwsStateError,
    );
    expect(storage.getString('profile_name'), 'A-NAME');
    expect(storage.getString('user_name'), 'A-NAME');
  });

  test('a thrown name write leaves the durable name unchanged', () async {
    final storage = _ScriptedStorage();
    await storage.setString('profile_name', 'A-NAME');
    await storage.setString('user_name', 'A-NAME');
    storage.throwNextUserName = true;
    final repo = MockUserRepository(storage);
    await expectLater(
      repo.renameDisplayName('NEW-NAME', stillOwner: () => true),
      throwsStateError,
    );
    expect(storage.getString('profile_name'), 'A-NAME');
    expect(storage.getString('user_name'), 'A-NAME');
  });

  test('a held rename cannot repopulate owner A after a real switch', () async {
    final storage = _ScriptedStorage();
    final isolation = UserLocalDataIsolation(
      storage,
      secureStorage: InMemorySecureStorage(),
    );
    final signedA = await isolation.onSignedIn('owner-a');
    expect(signedA.success, isTrue);
    await _seedOwnerA(storage);
    storage.holdAfterProfileName = Completer<void>();
    final repo = MockUserRepository(storage);
    final container = ProviderContainer(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
        userRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    expect((await container.read(userProfileProvider.future)).name, 'A-NAME');

    final pending = container
        .read(userProfileProvider.notifier)
        .saveName('A-RENAMED');
    await Future<void>.delayed(Duration.zero);
    expect(storage.getString('profile_name'), 'A-RENAMED');

    final switched = await isolation.onSignedIn('owner-b');
    expect(switched.success, isTrue);
    storage.holdAfterProfileName!.complete();
    await pending;

    _expectNoOwnerA(storage);
    expect(container.read(userProfileProvider).value?.name, isNot('A-RENAMED'));
  });

  test('owner B keeps a legitimate same display name', () async {
    final storage = _ScriptedStorage();
    final isolation = UserLocalDataIsolation(
      storage,
      secureStorage: InMemorySecureStorage(),
    );
    expect((await isolation.onSignedIn('owner-a')).success, isTrue);
    await _seedOwnerA(storage);
    storage.holdAfterProfileName = Completer<void>();
    final pending = MockUserRepository(storage).renameDisplayName(
      'Alex',
      stillOwner: () =>
          UserLocalDataIsolation.accountSwitchEpoch.value == savedEpoch,
    );
    await Future<void>.delayed(Duration.zero);
    expect((await isolation.onSignedIn('owner-b')).success, isTrue);
    await storage.setString('profile_name', 'Alex');
    await storage.setString('user_name', 'Alex');
    storage.holdAfterProfileName!.complete();
    await pending;
    expect(storage.getString('profile_name'), 'Alex');
    expect(storage.getString('user_name'), 'Alex');
    expect(storage.getString('profile_job'), isNull);
  });

  testWidgets('a failed rename shows the existing failure copy', (
    tester,
  ) async {
    final storage = _ScriptedStorage();
    await storage.setString('profile_name', 'Ada');
    storage.failNextProfileName = true;
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        overrides: [
          userRepositoryProvider.overrideWithValue(MockUserRepository(storage)),
        ],
        child: const MaterialApp(home: ProfileReferenceScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextField), 'Bora');
    await tester.tap(find.text('Kaydet'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text(ResilienceCopy.genericLoadFailed), findsOneWidget);
    expect(find.text('Ada'), findsWidgets);
    expect(storage.getString('profile_name'), 'Ada');
    expect(storage.getString('user_name'), isNull);
  });
}

Future<void> _seedOwnerA(_ScriptedStorage storage) async {
  await storage.setString('profile_name', 'A-NAME');
  await storage.setString('user_name', 'A-NAME');
  await storage.setString('profile_job', 'A-JOB');
  await storage.setStringList('profile_interests', ['A-INTEREST']);
  await storage.setStringList('profile_goals', ['A-GOAL']);
  await storage.setInt('profile_streak', 4);
  await storage.setInt('profile_readings', 9);
  await storage.setDouble('profile_spiritual', 3);
  await storage.setString('profile_favorite_deck', 'A-DECK');
  await storage.setStringList('profile_achievements', ['A-ACH']);
}

void _expectNoOwnerA(_ScriptedStorage storage) {
  expect(storage.getString('profile_name'), isNull);
  expect(storage.getString('user_name'), isNull);
  expect(storage.getString('profile_job'), isNull);
  expect(storage.getStringList('profile_interests'), isNull);
  expect(storage.getStringList('profile_goals'), isNull);
  expect(storage.getInt('profile_streak'), isNull);
  expect(storage.getInt('profile_readings'), isNull);
  expect(storage.getDouble('profile_spiritual'), isNull);
  expect(storage.getString('profile_favorite_deck'), isNull);
  expect(storage.getStringList('profile_achievements'), isNull);
}

class _ScriptedStorage extends LocalStorage {
  _ScriptedStorage() : super.ephemeral();

  Completer<void>? holdAfterProfileName;
  bool _heldProfileName = false;
  bool failNextProfileName = false;
  bool failNextUserName = false;
  bool throwNextUserName = false;
  final List<String> writes = [];

  @override
  Future<bool> setString(String key, String value) async {
    if (key == 'profile_name' || key == 'user_name') writes.add(key);
    if (key == 'profile_name' && failNextProfileName) {
      failNextProfileName = false;
      return false;
    }
    if (key == 'user_name' && failNextUserName) {
      failNextUserName = false;
      return false;
    }
    if (key == 'user_name' && throwNextUserName) {
      throwNextUserName = false;
      throw StateError('user_name');
    }
    final ok = await super.setString(key, value);
    final hold = holdAfterProfileName;
    if (key == 'profile_name' &&
        hold != null &&
        !_heldProfileName &&
        !hold.isCompleted) {
      _heldProfileName = true;
      await hold.future;
    }
    return ok;
  }
}
