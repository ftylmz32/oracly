/// P4C — daily snapshot waits for settled personalization.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/domain/models/user_profile.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/notifications/memory_notification_port.dart';
import 'package:oracly_new/core/notifications/oracly_notification_providers.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/daily_message/data/daily_return_store.dart';
import 'package:oracly_new/features/daily_message/presentation/screens/daily_message_screen.dart';
import 'package:oracly_new/features/daily_message/services/daily_message_service.dart';
import 'package:oracly_new/features/personal_discovery/models/cross_discovery_insight.dart';
import 'package:oracly_new/features/personal_discovery/models/discovery_theme_strength.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_profile.dart';
import 'package:oracly_new/features/personal_discovery/providers/personal_discovery_providers.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';
import 'package:oracly_new/features/premium/providers/premium_purchase_port_provider.dart';
import 'package:oracly_new/features/premium/services/unavailable_premium_purchase.dart';
import 'package:oracly_new/shared/widgets/oracly_cinematic_loading.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  testWidgets('loaded personalization is the snapshot that gets stored', (
    tester,
  ) async {
    final storage = LocalStorage.ephemeral();
    final container = _container(
      storage,
      profile: _ReadyProfile(const UserProfileModel(name: 'Fatih')),
      settings: _ReadySettings(const PersonalizationSettings()),
      discovery: () async => _themed,
    );
    addTearDown(container.dispose);
    await container.read(userProfileProvider.future);
    await container.read(settingsProvider.future);
    await container.read(personalDiscoveryProfileProvider.future);

    await tester.pumpWidget(_app(container));
    await tester.pump();

    expect(find.byType(OraclyCinematicLoading), findsNothing);
    expect(find.textContaining('sınırlar'), findsWidgets);
    await tester.pump();
    await tester.pump();

    final stored = DailyReturnStore(storage).readToday(DateTime.now());
    expect(stored?.text, contains('sınırlar'));
  });

  testWidgets('held loading does not freeze a generic daily snapshot', (
    tester,
  ) async {
    final storage = LocalStorage.ephemeral();
    final profile = _HeldProfile();
    final settings = _HeldSettings();
    final discovery = Completer<PersonalDiscoveryProfile>();
    final container = _container(
      storage,
      profile: profile,
      settings: settings,
      discovery: () => discovery.future,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_app(container));
    await tester.pump();

    expect(find.byType(OraclyCinematicLoading), findsOneWidget);
    expect(find.textContaining('sınırlar'), findsNothing);
    expect(DailyReturnStore(storage).readToday(DateTime.now()), isNull);

    profile.completer.complete(const UserProfileModel(name: 'Fatih'));
    settings.completer.complete(const PersonalizationSettings());
    discovery.complete(_themed);
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.byType(OraclyCinematicLoading), findsNothing);
    expect(find.textContaining('sınırlar'), findsWidgets);
    final stored = DailyReturnStore(storage).readToday(DateTime.now());
    expect(stored?.text, contains('sınırlar'));

    await tester.pumpWidget(_app(container));
    await tester.pump();
    expect(find.textContaining('sınırlar'), findsWidgets);
    expect(
      DailyReturnStore(storage).readToday(DateTime.now())?.text,
      stored?.text,
    );
  });

  testWidgets('empty settled profile stores one honest generic message', (
    tester,
  ) async {
    final storage = LocalStorage.ephemeral();
    final container = _container(
      storage,
      profile: _ReadyProfile(const UserProfileModel()),
      settings: _ReadySettings(const PersonalizationSettings()),
      discovery: () async => PersonalDiscoveryProfile.empty,
    );
    addTearDown(container.dispose);
    await container.read(userProfileProvider.future);
    await container.read(settingsProvider.future);
    await container.read(personalDiscoveryProfileProvider.future);

    final expected = DailyMessageService.forDay(
      day: DateTime.now(),
      personality: AiPersonality.mystical,
    );

    await tester.pumpWidget(_app(container));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text(expected.text), findsOneWidget);
    expect(find.textContaining('Fatih'), findsNothing);
    expect(find.textContaining('sınırlar'), findsNothing);
    final stored = DailyReturnStore(storage).readToday(DateTime.now());
    expect(stored?.text, expected.text);

    await tester.pumpWidget(_app(container));
    await tester.pump();
    expect(find.text(expected.text), findsOneWidget);
    expect(
      DailyReturnStore(storage).readToday(DateTime.now())?.text,
      expected.text,
    );
  });

  testWidgets('cached today wins before personalization loads', (tester) async {
    final storage = LocalStorage.ephemeral();
    await DailyReturnStore(
      storage,
    ).commit(DailyMessage(text: 'P4C-CACHED-SENTINEL', day: DateTime.now()));
    final container = _container(
      storage,
      profile: _HeldProfile(),
      settings: _HeldSettings(),
      discovery: () => Completer<PersonalDiscoveryProfile>().future,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_app(container));
    await tester.pump();

    expect(find.byType(OraclyCinematicLoading), findsNothing);
    expect(find.textContaining('P4C-CACHED-SENTINEL'), findsWidgets);
    expect(
      DailyReturnStore(storage).readToday(DateTime.now())?.text,
      'P4C-CACHED-SENTINEL',
    );

    OraclyL10n.bind('en');
    await tester.pump();
    expect(find.textContaining('P4C-CACHED-SENTINEL'), findsWidgets);
    expect(
      DailyReturnStore(storage).readToday(DateTime.now())?.text,
      'P4C-CACHED-SENTINEL',
    );
    OraclyL10n.bind('tr');
  });

  testWidgets('settled daily message fits a short phone and large text', (
    tester,
  ) async {
    final storage = LocalStorage.ephemeral();
    final container = _container(
      storage,
      profile: _ReadyProfile(const UserProfileModel(name: 'Fatih')),
      settings: _ReadySettings(const PersonalizationSettings()),
      discovery: () async => _themed,
    );
    addTearDown(container.dispose);
    await container.read(userProfileProvider.future);
    await container.read(settingsProvider.future);
    await container.read(personalDiscoveryProfileProvider.future);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final size in const [Size(320, 568), Size(360, 640), Size(390, 844)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(_app(container, textScale: 1.4));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('sınırlar'), findsWidgets);
    }
  });
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

class _HeldProfile extends UserProfileNotifier {
  final completer = Completer<UserProfileModel>();

  @override
  Future<UserProfileModel> build() => completer.future;
}

class _ReadyProfile extends UserProfileNotifier {
  _ReadyProfile(this.value);

  final UserProfileModel value;

  @override
  Future<UserProfileModel> build() async => value;
}

class _HeldSettings extends SettingsNotifier {
  final completer = Completer<PersonalizationSettings>();

  @override
  Future<PersonalizationSettings> build() => completer.future;
}

class _ReadySettings extends SettingsNotifier {
  _ReadySettings(this.value);

  final PersonalizationSettings value;

  @override
  Future<PersonalizationSettings> build() async => value;
}

Widget _app(ProviderContainer container, {double textScale = 1}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const DailyMessageScreen(),
    ),
  );
}

ProviderContainer _container(
  LocalStorage storage, {
  required UserProfileNotifier profile,
  required SettingsNotifier settings,
  required Future<PersonalDiscoveryProfile> Function() discovery,
}) {
  return ProviderContainer(
    overrides: _overrides(
      storage,
      profile: profile,
      settings: settings,
      discovery: discovery,
    ),
  );
}

List<Override> _overrides(
  LocalStorage storage, {
  required UserProfileNotifier profile,
  required SettingsNotifier settings,
  required Future<PersonalDiscoveryProfile> Function() discovery,
}) {
  return [
    localStorageProvider.overrideWithValue(storage),
    secureStorageProvider.overrideWithValue(InMemorySecureStorage()),
    oraclyNotificationPortProvider.overrideWithValue(MemoryNotificationPort()),
    premiumPurchasePortProvider.overrideWithValue(
      const UnavailablePremiumPurchase(),
    ),
    userProfileProvider.overrideWith(() => profile),
    settingsProvider.overrideWith(() => settings),
    personalDiscoveryProfileProvider.overrideWith((ref) => discovery()),
  ];
}
