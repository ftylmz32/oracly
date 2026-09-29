/// P4C.1 — mounted personal surfaces drop owner A when the switch epoch bumps.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/domain/models/conversation_record.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/core/domain/models/user_profile.dart';
import 'package:oracly_new/core/intelligence/domain/models/favorite_card_ref.dart';
import 'package:oracly_new/core/intelligence/domain/models/intelligence_snapshot.dart';
import 'package:oracly_new/core/intelligence/domain/models/reflection_entry.dart';
import 'package:oracly_new/core/intelligence/domain/models/ritual_history_entry.dart';
import 'package:oracly_new/core/intelligence/domain/repositories/intelligence_repository.dart';
import 'package:oracly_new/core/intelligence/services/intelligence_layer_service.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/notifications/memory_notification_port.dart';
import 'package:oracly_new/core/notifications/oracly_notification_providers.dart';
import 'package:oracly_new/core/reflection/services/reflection_engine_service.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/daily_message/data/daily_return_store.dart';
import 'package:oracly_new/features/daily_message/models/daily_message.dart';
import 'package:oracly_new/features/daily_message/presentation/screens/daily_message_screen.dart';
import 'package:oracly_new/features/daily_message/services/daily_message_readiness.dart';
import 'package:oracly_new/features/daily_message/services/daily_message_session.dart';
import 'package:oracly_new/features/insights/data/personal_insights_preferences_repository.dart';
import 'package:oracly_new/features/insights/models/insight.dart';
import 'package:oracly_new/features/insights/models/insight_category.dart';
import 'package:oracly_new/features/insights/models/reflection_summary.dart';
import 'package:oracly_new/features/insights/presentation/screens/personal_insights_screen.dart';
import 'package:oracly_new/features/insights/providers/insights_providers.dart';
import 'package:oracly_new/features/insights/services/personal_insights_experience_service.dart';
import 'package:oracly_new/features/personal_discovery/data/discovery_surface_memory.dart';
import 'package:oracly_new/features/personal_discovery/models/cross_discovery_insight.dart';
import 'package:oracly_new/features/personal_discovery/models/discovery_theme_strength.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_profile.dart';
import 'package:oracly_new/features/personal_discovery/providers/personal_discovery_providers.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';
import 'package:oracly_new/features/premium/providers/premium_purchase_port_provider.dart';
import 'package:oracly_new/features/premium/services/unavailable_premium_purchase.dart';
import 'package:oracly_new/models/memory_item.dart';
import 'package:oracly_new/screens/memory/memory_screen.dart';
import 'package:oracly_new/screens/profile/reference/profile_daily_return_card.dart';
import 'package:oracly_new/services/memory_service.dart';

import '../../support/test_path_provider.dart';

void main() {
  late int savedEpoch;
  late Directory docsRoot;

  setUp(() async {
    OraclyL10n.bind('tr');
    savedEpoch = UserLocalDataIsolation.accountSwitchEpoch.value;
    docsRoot = await installTestPathProvider('p4c1-');
  });

  tearDown(() {
    final epoch = UserLocalDataIsolation.accountSwitchEpoch;
    if (epoch.value != savedEpoch) epoch.value = savedEpoch;
    if (docsRoot.existsSync()) docsRoot.deleteSync(recursive: true);
  });

  test(
    'a reload keeps the previous profile until the next value arrives',
    () async {
      final storage = LocalStorage.ephemeral();
      final profile = _ReplayProfile();
      final settings = _ReplaySettings();
      final discovery = <Completer<PersonalDiscoveryProfile>>[];
      final container = _container(
        storage,
        profile: profile,
        settings: settings,
        discovery: () {
          final next = Completer<PersonalDiscoveryProfile>();
          discovery.add(next);
          return next.future;
        },
      );
      addTearDown(container.dispose);
      final profileSub = container.listen(userProfileProvider, (_, _) {});
      final settingsSub = container.listen(settingsProvider, (_, _) {});
      final discoverySub = container.listen(
        personalDiscoveryProfileProvider,
        (_, _) {},
      );
      addTearDown(profileSub.close);
      addTearDown(settingsSub.close);
      addTearDown(discoverySub.close);

      profile.calls.first.complete(const UserProfileModel(name: 'OwnerA'));
      settings.calls.first.complete(const PersonalizationSettings());
      discovery.first.complete(PersonalDiscoveryProfile.empty);
      await container.read(userProfileProvider.future);
      await container.read(settingsProvider.future);
      await container.read(personalDiscoveryProfileProvider.future);

      container.invalidate(userProfileProvider);
      container.invalidate(settingsProvider);
      container.invalidate(personalDiscoveryProfileProvider);
      await Future<void>.value();

      final heldProfile = container.read(userProfileProvider);
      final heldSettings = container.read(settingsProvider);
      final heldDiscovery = container.read(personalDiscoveryProfileProvider);
      expect(heldProfile.value?.name, 'OwnerA');
      expect(heldProfile.isRefreshing || heldProfile.isReloading, isTrue);
      expect(DailyMessageReadiness.settled(heldProfile), isFalse);
      expect(DailyMessageReadiness.settled(heldSettings), isFalse);
      expect(DailyMessageReadiness.settled(heldDiscovery), isFalse);

      profile.calls.last.complete(const UserProfileModel(name: 'OwnerB'));
      settings.calls.last.complete(const PersonalizationSettings());
      discovery.last.complete(PersonalDiscoveryProfile.empty);
      await container.read(userProfileProvider.future);
      expect(container.read(userProfileProvider).value?.name, 'OwnerB');
      expect(
        DailyMessageReadiness.settled(container.read(userProfileProvider)),
        isTrue,
      );
    },
  );

  test(
    'a daily persist captured under the previous epoch does not write',
    () async {
      final storage = LocalStorage.ephemeral();
      final epoch = UserLocalDataIsolation.accountSwitchEpoch.value;
      await DailyMessageSession.persist(
        store: DailyReturnStore(storage),
        memory: DiscoverySurfaceMemory(storage),
        message: DailyMessage(
          text: 'OWNER-A-DAILY',
          day: DateTime.now(),
          theme: 'sınırlar',
        ),
        ownerEpoch: epoch - 1,
      );
      expect(DailyReturnStore(storage).readToday(DateTime.now()), isNull);
      expect(DiscoverySurfaceMemory(storage).all(), isEmpty);
    },
  );

  testWidgets('a scheduled daily write from A does not land in B storage', (
    tester,
  ) async {
    final storage = LocalStorage.ephemeral();
    final secure = InMemorySecureStorage();
    final isolation = UserLocalDataIsolation(storage, secureStorage: secure);
    await isolation.onSignedIn('owner-a');
    final container = _container(
      storage,
      secure: secure,
      profile: _OwnerProfile(storage),
      settings: _OwnerSettings(),
      discovery: () async {
        final owner = storage.getString(UserLocalDataIsolation.ownerKey);
        if (owner == 'owner-b') return PersonalDiscoveryProfile.empty;
        return _themed;
      },
    );
    addTearDown(container.dispose);
    await container.read(userProfileProvider.future);
    await container.read(settingsProvider.future);
    await container.read(personalDiscoveryProfileProvider.future);

    await tester.pumpWidget(
      _scope(
        container,
        child: _EpochBeforePersist(
          storage: storage,
          child: const MaterialApp(home: DailyMessageScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    final stored = DailyReturnStore(storage).readToday(DateTime.now());
    expect(stored, isNotNull);
    expect(stored!.text, isNot(contains('sınırlar')));
    expect(
      DiscoverySurfaceMemory(storage).all().map((row) => row.theme),
      isNot(contains('sınırlar')),
    );
    final again = DailyReturnStore(storage).readToday(DateTime.now())?.text;
    await tester.pump();
    expect(DailyReturnStore(storage).readToday(DateTime.now())?.text, again);
    expect(DailyReturnStore(storage).historyTexts(), [stored.text]);
  });

  testWidgets('a mounted daily screen stores one B snapshot after the switch', (
    tester,
  ) async {
    final harness = await _readyDaily();
    addTearDown(harness.container.dispose);
    await tester.pumpWidget(
      _scope(
        harness.container,
        child: const MaterialApp(home: DailyMessageScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(
      DailyReturnStore(harness.storage).readToday(DateTime.now())?.text,
      contains('sınırlar'),
    );

    await _switch(tester, harness.isolation, 'owner-b');
    await tester.pump();
    await tester.pump();
    await tester.pump();

    final stored = DailyReturnStore(harness.storage).readToday(DateTime.now());
    expect(stored, isNotNull);
    expect(stored!.text, isNot(contains('sınırlar')));
    expect(find.textContaining('sınırlar'), findsNothing);
    expect(
      DiscoverySurfaceMemory(harness.storage).all().map((row) => row.theme),
      isNot(contains('sınırlar')),
    );
    await tester.pump();
    expect(
      DailyReturnStore(harness.storage).readToday(DateTime.now())?.text,
      stored.text,
    );
  });

  testWidgets('the profile card follows the same owner switch', (tester) async {
    final harness = await _readyDaily();
    addTearDown(harness.container.dispose);
    await tester.pumpWidget(
      _scope(
        harness.container,
        child: const MaterialApp(
          home: Scaffold(body: ProfileDailyReturnCard()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('sınırlar'), findsWidgets);

    await _switch(tester, harness.isolation, 'owner-b');
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('sınırlar'), findsNothing);
    final stored = DailyReturnStore(harness.storage).readToday(DateTime.now());
    expect(stored?.text, isNot(contains('sınırlar')));
    await tester.pumpWidget(const SizedBox.shrink());

    final cached = LocalStorage.ephemeral();
    await cached.setString(UserLocalDataIsolation.ownerKey, 'owner-b');
    await DailyReturnStore(
      cached,
    ).commit(DailyMessage(text: 'B-CACHED-SENTINEL', day: DateTime.now()));
    final held = Completer<UserProfileModel>();
    final heldDiscovery = Completer<PersonalDiscoveryProfile>();
    final container = _container(
      cached,
      profile: _HeldProfile(held.future),
      settings: _ReadySettings(const PersonalizationSettings()),
      discovery: () => heldDiscovery.future,
    );
    addTearDown(() {
      if (!held.isCompleted) held.complete(const UserProfileModel());
      if (!heldDiscovery.isCompleted) {
        heldDiscovery.complete(PersonalDiscoveryProfile.empty);
      }
    });
    addTearDown(container.dispose);
    await tester.pumpWidget(
      _scope(
        container,
        child: const MaterialApp(
          home: Scaffold(body: ProfileDailyReturnCard()),
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('B-CACHED-SENTINEL'), findsOneWidget);
    expect(
      DailyReturnStore(cached).readToday(DateTime.now())?.text,
      'B-CACHED-SENTINEL',
    );
  });

  testWidgets('an open memory list drops A and ignores a late A load', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final storage = LocalStorage.ephemeral();
    final secure = InMemorySecureStorage();
    final isolation = UserLocalDataIsolation(storage, secureStorage: secure);
    await isolation.onSignedIn('owner-a');
    final memory = _HoldingMemory(storage);
    await memory.addAdvancedMemory(
      MemoryItem(
        category: 'interest',
        content: 'OWNER-A-NOTE',
        importance: 'high',
        createdAt: DateTime(2026, 9, 1),
      ),
    );
    final container = _bare(storage, secure, [
      memoryServiceProvider.overrideWithValue(memory),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _scope(container, child: const MaterialApp(home: MemoryScreen())),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('OWNER-A-NOTE'), findsOneWidget);

    await _switch(tester, isolation, 'owner-b');
    await tester.pump();
    expect(find.text('OWNER-A-NOTE'), findsNothing);
    await tester.pump();
    expect(find.text('OWNER-A-NOTE'), findsNothing);

    final late = Completer<List<MemoryItem>>();
    final lateMemory = _HoldingMemory(storage);
    lateMemory.holdNext = late;
    final lateContainer = _bare(storage, secure, [
      memoryServiceProvider.overrideWithValue(lateMemory),
    ]);
    addTearDown(lateContainer.dispose);
    await tester.pumpWidget(
      _scope(lateContainer, child: const MaterialApp(home: MemoryScreen())),
    );
    await tester.pump();
    expect(find.text('OWNER-A-NOTE'), findsNothing);

    await _switch(tester, isolation, 'owner-c');
    await tester.pump();
    late.complete([
      MemoryItem(
        category: 'interest',
        content: 'OWNER-A-NOTE',
        importance: 'high',
        createdAt: DateTime(2026, 9, 1),
      ),
    ]);
    await tester.pump();
    await tester.pump();
    expect(find.text('OWNER-A-NOTE'), findsNothing);
  });

  testWidgets('an open insights letter becomes B and ignores a late A load', (
    tester,
  ) async {
    final storage = LocalStorage.ephemeral();
    final secure = InMemorySecureStorage();
    final isolation = UserLocalDataIsolation(storage, secureStorage: secure);
    await isolation.onSignedIn('owner-a');
    final service = _SwitchingInsights();
    final container = _bare(storage, secure, [
      personalInsightsExperienceServiceProvider.overrideWithValue(service),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _scope(
        container,
        child: const MaterialApp(home: PersonalInsightsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('OWNER-A-INSIGHT'), findsWidgets);

    await _switch(tester, isolation, 'owner-b');
    await tester.pump();
    await tester.pump();
    expect(find.text('OWNER-A-INSIGHT'), findsNothing);
    expect(find.text('OWNER-B-INSIGHT'), findsWidgets);

    final lateService = _SwitchingInsights();
    final lateLoad = Completer<InsightReflectionSummary>();
    lateService.holdNext = lateLoad;
    final lateContainer = _bare(storage, secure, [
      personalInsightsExperienceServiceProvider.overrideWithValue(lateService),
    ]);
    addTearDown(lateContainer.dispose);
    await tester.pumpWidget(
      _scope(
        lateContainer,
        child: const MaterialApp(home: PersonalInsightsScreen()),
      ),
    );
    await tester.pump();
    expect(find.text('OWNER-A-INSIGHT'), findsNothing);

    await _switch(tester, isolation, 'owner-c');
    await tester.pump();
    lateLoad.complete(_letter('OWNER-A-INSIGHT'));
    await tester.pump();
    await tester.pump();
    expect(find.text('OWNER-A-INSIGHT'), findsNothing);
    expect(find.text('OWNER-B-INSIGHT'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _switch(
  WidgetTester tester,
  UserLocalDataIsolation isolation,
  String uid,
) {
  return tester.runAsync(() => isolation.onSignedIn(uid)).then((_) {});
}

Future<_DailyHarness> _readyDaily() async {
  final storage = LocalStorage.ephemeral();
  final secure = InMemorySecureStorage();
  final isolation = UserLocalDataIsolation(storage, secureStorage: secure);
  await isolation.onSignedIn('owner-a');
  final container = _container(
    storage,
    secure: secure,
    profile: _OwnerProfile(storage),
    settings: _OwnerSettings(),
    discovery: () async {
      final owner = storage.getString(UserLocalDataIsolation.ownerKey);
      if (owner == 'owner-b') return PersonalDiscoveryProfile.empty;
      return _themed;
    },
  );
  await container.read(userProfileProvider.future);
  await container.read(settingsProvider.future);
  await container.read(personalDiscoveryProfileProvider.future);
  return _DailyHarness(storage, isolation, container);
}

class _DailyHarness {
  _DailyHarness(this.storage, this.isolation, this.container);

  final LocalStorage storage;
  final UserLocalDataIsolation isolation;
  final ProviderContainer container;
}

Widget _scope(ProviderContainer container, {required Widget child}) {
  return UncontrolledProviderScope(
    container: container,
    child: _PersonalInputRefresh(child: child),
  );
}

/// Same epoch signal as [AccountSwitchRefreshHost], limited to the three
/// personalization inputs these surfaces read. The full host also rebuilds
/// gems and OR, which retry against the network in widget tests.
class _PersonalInputRefresh extends ConsumerStatefulWidget {
  const _PersonalInputRefresh({required this.child});

  final Widget child;

  @override
  ConsumerState<_PersonalInputRefresh> createState() =>
      _PersonalInputRefreshState();
}

class _PersonalInputRefreshState extends ConsumerState<_PersonalInputRefresh> {
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
    ref.invalidate(userProfileProvider);
    ref.invalidate(settingsProvider);
    ref.invalidate(personalDiscoveryProfileProvider);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

ProviderContainer _bare(
  LocalStorage storage,
  InMemorySecureStorage secure,
  List<Override> extra,
) {
  return ProviderContainer(
    overrides: [
      localStorageProvider.overrideWithValue(storage),
      secureStorageProvider.overrideWithValue(secure),
      oraclyNotificationPortProvider.overrideWithValue(
        MemoryNotificationPort(),
      ),
      premiumPurchasePortProvider.overrideWithValue(
        const UnavailablePremiumPurchase(),
      ),
      ...extra,
    ],
  );
}

ProviderContainer _container(
  LocalStorage storage, {
  InMemorySecureStorage? secure,
  required UserProfileNotifier profile,
  required SettingsNotifier settings,
  required Future<PersonalDiscoveryProfile> Function() discovery,
}) {
  return ProviderContainer(
    overrides: [
      localStorageProvider.overrideWithValue(storage),
      secureStorageProvider.overrideWithValue(
        secure ?? InMemorySecureStorage(),
      ),
      oraclyNotificationPortProvider.overrideWithValue(
        MemoryNotificationPort(),
      ),
      premiumPurchasePortProvider.overrideWithValue(
        const UnavailablePremiumPurchase(),
      ),
      userProfileProvider.overrideWith(() => profile),
      settingsProvider.overrideWith(() => settings),
      personalDiscoveryProfileProvider.overrideWith((ref) => discovery()),
    ],
  );
}

class _EpochBeforePersist extends StatefulWidget {
  const _EpochBeforePersist({required this.storage, required this.child});

  final LocalStorage storage;
  final Widget child;

  @override
  State<_EpochBeforePersist> createState() => _EpochBeforePersistState();
}

class _EpochBeforePersistState extends State<_EpochBeforePersist> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.storage.remove(DailyReturnStore.todayKey);
      widget.storage.remove(DailyReturnStore.previousKey);
      widget.storage.remove(DailyReturnStore.historyKey);
      widget.storage.remove(DiscoverySurfaceMemory.key);
      widget.storage.setString(UserLocalDataIsolation.ownerKey, 'owner-b');
      UserLocalDataIsolation.accountSwitchEpoch.value++;
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _OwnerProfile extends UserProfileNotifier {
  _OwnerProfile(this.storage);

  final LocalStorage storage;

  @override
  Future<UserProfileModel> build() async {
    final owner = storage.getString(UserLocalDataIsolation.ownerKey);
    if (owner == 'owner-b') return const UserProfileModel(name: 'Beren');
    return const UserProfileModel(name: 'Fatih');
  }
}

class _OwnerSettings extends SettingsNotifier {
  @override
  Future<PersonalizationSettings> build() async =>
      const PersonalizationSettings();
}

class _ReplayProfile extends UserProfileNotifier {
  final calls = <Completer<UserProfileModel>>[];

  @override
  Future<UserProfileModel> build() {
    final next = Completer<UserProfileModel>();
    calls.add(next);
    return next.future;
  }
}

class _ReplaySettings extends SettingsNotifier {
  final calls = <Completer<PersonalizationSettings>>[];

  @override
  Future<PersonalizationSettings> build() {
    final next = Completer<PersonalizationSettings>();
    calls.add(next);
    return next.future;
  }
}

class _HeldProfile extends UserProfileNotifier {
  _HeldProfile(this.pending);

  final Future<UserProfileModel> pending;

  @override
  Future<UserProfileModel> build() => pending;
}

class _ReadySettings extends SettingsNotifier {
  _ReadySettings(this.value);

  final PersonalizationSettings value;

  @override
  Future<PersonalizationSettings> build() async => value;
}

class _HoldingMemory extends MemoryService {
  _HoldingMemory(super.storage);

  Completer<List<MemoryItem>>? holdNext;

  @override
  Future<List<MemoryItem>> getAdvancedMemories() {
    final pending = holdNext;
    if (pending != null) {
      holdNext = null;
      return pending.future;
    }
    return super.getAdvancedMemories();
  }
}

class _SwitchingInsights extends PersonalInsightsExperienceService {
  _SwitchingInsights()
    : super(
        reflectionEngine: ReflectionEngineService(
          intelligence: const IntelligenceLayerService(_UnusedIntelligence()),
        ),
        preferences: PersonalInsightsPreferencesRepository(
          LocalStorage.ephemeral(),
        ),
      );

  Completer<InsightReflectionSummary>? holdNext;
  var calls = 0;

  @override
  Future<InsightReflectionSummary> generate({DateTime? asOf}) {
    calls++;
    final pending = holdNext;
    if (pending != null) {
      holdNext = null;
      return pending.future;
    }
    final label = calls == 1 ? 'OWNER-A-INSIGHT' : 'OWNER-B-INSIGHT';
    return Future.value(_letter(label));
  }

  @override
  Future<InsightReflectionSummary> applyPrivacyFilters(
    InsightReflectionSummary summary,
  ) async {
    return summary;
  }
}

InsightReflectionSummary _letter(String salutation) {
  return InsightReflectionSummary(
    salutation: salutation,
    generatedAt: DateTime(2026, 9, 1),
    insights: [
      Insight(
        id: 'visible-only',
        category: InsightCategory.recurringTheme,
        title: salutation,
        body: 'Observed',
        generatedAt: DateTime(2026, 9, 1),
      ),
    ],
  );
}

class _UnusedIntelligence implements IntelligenceRepository {
  const _UnusedIntelligence();

  @override
  Future<IntelligenceSnapshot> loadSnapshot() => throw UnimplementedError();

  @override
  Future<List<ReadingModel>> getReadings() => throw UnimplementedError();

  @override
  Future<List<FavoriteCardRef>> getFavoriteCards() =>
      throw UnimplementedError();

  @override
  Future<List<ReflectionEntry>> getReflections() => throw UnimplementedError();

  @override
  Future<List<ConversationRecord>> getConversations() =>
      throw UnimplementedError();

  @override
  Future<List<RitualHistoryEntry>> getRitualHistory() =>
      throw UnimplementedError();
}

final _themed = PersonalDiscoveryProfile(
  tarotCount: 2,
  dreamCount: 1,
  crossInsights: [
    CrossDiscoveryInsight(
      theme: 'sınırlar',
      sources: const ['tarot', 'dream'],
      confidence: DiscoveryThemeStrength.strong,
      lastObserved: DateTime(2026, 9, 1),
      sourceCount: 2,
      discoveryCount: 3,
      recencyWeight: 0.9,
    ),
  ],
);
