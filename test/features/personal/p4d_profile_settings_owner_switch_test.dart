/// P4D — Profile resume and Settings name drop owner A on a real switch.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/domain/models/conversation_record.dart';
import 'package:oracly_new/core/domain/repositories/ai_conversation_repository.dart';
import 'package:oracly_new/core/experience/providers/continue_where_you_left_off_provider.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/tarot/data/datasources/tarot_local_datasource.dart';
import 'package:oracly_new/screens/profile/data/profile_photo_store.dart';
import 'package:oracly_new/screens/profile/reference/profile_reference_avatar.dart';
import 'package:oracly_new/screens/profile/reference/profile_reference_screen.dart';
import 'package:oracly_new/screens/settings/reference/settings_reference_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_path_provider.dart';
import '../../test_helpers/provider_scope_harness.dart';
import '../../screens/settings/settings_test_fakes.dart';

const _ownerASession = 'session-owner-a';

final Uint8List _png1x1 = Uint8List.fromList(const [
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late int savedEpoch;
  late Directory docsRoot;

  setUp(() async {
    OraclyL10n.bind('tr');
    savedEpoch = UserLocalDataIsolation.accountSwitchEpoch.value;
    docsRoot = await installTestPathProvider('p4d-');
  });

  tearDown(() {
    final epoch = UserLocalDataIsolation.accountSwitchEpoch;
    if (epoch.value != savedEpoch) epoch.value = savedEpoch;
    if (docsRoot.existsSync()) docsRoot.deleteSync(recursive: true);
  });

  test('late owner A resume cannot repopulate after the epoch bumps', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await storage.setString(
      TarotLocalDataSource.activeKey,
      jsonEncode({
        'id': _ownerASession,
        'spread': 'single',
        'status': 'inProgress',
        'startedAt': '2026-01-02T00:00:00.000Z',
      }),
    );
    final held = _HeldConversations()..release();
    final container = ProviderContainer(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
        aiConversationRepositoryProvider.overrideWithValue(held),
      ],
    );
    addTearDown(container.dispose);

    final first = container.read(continueWhereYouLeftOffProvider.future);
    final ownerA = await first;
    expect(ownerA?.sessionId, _ownerASession);

    held.holdNext();
    await storage.remove(TarotLocalDataSource.activeKey);
    UserLocalDataIsolation.accountSwitchEpoch.value = savedEpoch + 1;
    await Future<void>.delayed(Duration.zero);

    final during = container.read(continueWhereYouLeftOffProvider);
    expect(during.isLoading, isTrue);

    held.release();
    final resolved = await container.read(
      continueWhereYouLeftOffProvider.future,
    );
    expect(resolved, isNull);
    expect(
      container.read(continueWhereYouLeftOffProvider).valueOrNull?.sessionId,
      isNot(_ownerASession),
    );
  });

  testWidgets('profile chrome fits 320 and large text', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.4)),
            child: child!,
          ),
          home: const ProfileReferenceScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    expect(find.text('ALANIN'), findsOneWidget);
  });

  testWidgets('profile hides owner A resume as soon as the switch starts', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await storage.setString(
      TarotLocalDataSource.activeKey,
      jsonEncode({
        'id': _ownerASession,
        'spread': 'single',
        'status': 'inProgress',
        'startedAt': '2026-01-02T00:00:00.000Z',
      }),
    );
    final held = _HeldConversations()..release();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        overrides: [aiConversationRepositoryProvider.overrideWithValue(held)],
        child: const MaterialApp(home: ProfileReferenceScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Devam Et'), findsOneWidget);
    expect(find.text(_ownerASession), findsNothing);

    held.holdNext();
    await storage.remove(TarotLocalDataSource.activeKey);
    UserLocalDataIsolation.accountSwitchEpoch.value = savedEpoch + 1;
    await tester.pump();

    expect(find.text('Devam Et'), findsNothing);
    expect(find.text(_ownerASession), findsNothing);

    held.release();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Devam Et'), findsNothing);
    expect(find.text(_ownerASession), findsNothing);
  });

  testWidgets('completed A to B switch leaves no owner A resume on profile', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    final isolation = UserLocalDataIsolation(
      storage,
      secureStorage: InMemorySecureStorage(),
    );
    final signedA = await tester.runAsync(
      () => isolation.onSignedIn('owner-a'),
    );
    expect(signedA!.success, isTrue);
    await storage.setString(
      TarotLocalDataSource.activeKey,
      jsonEncode({
        'id': _ownerASession,
        'spread': 'single',
        'status': 'inProgress',
        'startedAt': '2026-01-02T00:00:00.000Z',
      }),
    );
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: const MaterialApp(home: ProfileReferenceScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Devam Et'), findsOneWidget);

    final switched = await tester.runAsync(
      () => isolation.onSignedIn('owner-b'),
    );
    expect(switched!.success, isTrue);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Devam Et'), findsNothing);
    expect(find.text(_ownerASession), findsNothing);
    expect(
      storage.getString(TarotLocalDataSource.activeKey),
      anyOf(isNull, ''),
    );
  });

  testWidgets('open settings replaces owner A name after a completed switch', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(settingsTestLanguagePrefs);
    final storage = await LocalStorage.open();
    final isolation = UserLocalDataIsolation(
      storage,
      secureStorage: InMemorySecureStorage(),
    );
    final signedA = await tester.runAsync(
      () => isolation.onSignedIn('owner-a'),
    );
    expect(signedA!.success, isTrue);
    await storage.setString('profile_name', 'Owner A');
    final photo = File('${docsRoot.path}/owner-a.png');
    await tester.runAsync(() => photo.writeAsBytes(_png1x1));
    await storage.setString(ProfilePhotoStore.key, photo.path);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        overrides: [
          oraclySoundServiceProvider.overrideWithValue(SilentSound()),
          oraclyTtsProvider.overrideWithValue(SilentTts()),
        ],
        child: const MaterialApp(home: _SettingsSwitchHost()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Owner A'), findsOneWidget);
    expect(
      tester
          .widget<ProfileReferenceAvatar>(find.byType(ProfileReferenceAvatar))
          .photo,
      isNotNull,
    );

    final switched = await tester.runAsync(
      () => isolation.onSignedIn('owner-b'),
    );
    expect(switched!.success, isTrue);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Owner A'), findsNothing);
    expect(find.text('Yolcu'), findsOneWidget);
    expect(
      tester
          .widget<ProfileReferenceAvatar>(find.byType(ProfileReferenceAvatar))
          .photo,
      isNull,
    );
  });
}

class _HeldConversations implements AiConversationRepository {
  Completer<ConversationRecord?> _gate = Completer<ConversationRecord?>();

  void holdNext() => _gate = Completer<ConversationRecord?>();

  void release() {
    if (!_gate.isCompleted) _gate.complete(null);
  }

  @override
  Future<ConversationRecord?> getById(String id) => _gate.future;

  @override
  Future<List<ConversationRecord>> getAll() async => const [];

  @override
  Future<void> save(ConversationRecord record) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> sync() async {}
}

/// Mirrors the photo-epoch bump [PrivacyDataRefresh.afterAccountSwitch] already
/// performs. The full host also rebuilds gems and OR, which retry in tests.
class _SettingsSwitchHost extends ConsumerStatefulWidget {
  const _SettingsSwitchHost();

  @override
  ConsumerState<_SettingsSwitchHost> createState() =>
      _SettingsSwitchHostState();
}

class _SettingsSwitchHostState extends ConsumerState<_SettingsSwitchHost> {
  @override
  void initState() {
    super.initState();
    UserLocalDataIsolation.accountSwitchEpoch.addListener(_onSwitch);
  }

  @override
  void dispose() {
    UserLocalDataIsolation.accountSwitchEpoch.removeListener(_onSwitch);
    super.dispose();
  }

  void _onSwitch() {
    ref.read(profilePhotoEpochProvider.notifier).state++;
  }

  @override
  Widget build(BuildContext context) => const SettingsReferenceScreen();
}
