/// Freemium Aşama 3A — ad SDK + consent gate. Every SDK / UMP call goes
/// through a counting fake: "zero ad requests" means zero calls into the
/// SDK at all (no consent request, no SDK start), not just no ad load.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/feature_flags/feature_flag_runtime.dart';
import 'package:oracly_new/core/feature_flags/product_feature_flags.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ads/ads_environment.dart';
import 'package:oracly_new/features/ads/ads_rollout.dart';
import 'package:oracly_new/features/ads/controllers/ads_gate.dart';
import 'package:oracly_new/features/ads/presentation/ads_privacy_options_tile.dart';
import 'package:oracly_new/features/ads/providers/ads_providers.dart';
import 'package:oracly_new/features/ads/services/ads_sdk_port.dart';
import 'package:oracly_new/features/premium/models/premium_entitlement_state.dart';
import 'package:oracly_new/features/premium/providers/premium_providers.dart';

import '../../support/freemium_test_support.dart';

void setAdsFlag(bool on) {
  FeatureFlagRuntime.refreshFromRemote({
    ...ProductFeatureFlags.defaults(),
    ProductFeatureFlags.adsV1.key: on,
  });
}

/// Membership whose state can change mid-test (refresh / purchase / expiry).
class MutablePremium extends FakePremiumStatus {
  MutablePremium({
    bool loaded = true,
    bool premium = false,
    PremiumEntitlementState? entitlement,
    bool busy = false,
  }) : _l = loaded,
       _p = premium,
       _e =
           entitlement ??
           (premium
               ? PremiumEntitlementState.active
               : PremiumEntitlementState.inactive),
       _b = busy;

  bool _l;
  bool _p;
  PremiumEntitlementState _e;
  bool _b;

  void set({
    bool? loaded,
    bool? premium,
    PremiumEntitlementState? entitlement,
    bool? busy,
  }) {
    _l = loaded ?? _l;
    _p = premium ?? _p;
    _e = entitlement ?? _e;
    _b = busy ?? _b;
    notifyListeners();
  }

  @override
  bool get loaded => _l;
  @override
  bool get isPremium => _p;
  @override
  PremiumEntitlementState get entitlement => _e;
  @override
  bool get busy => _b;
}

class FakeAdsPort implements AdsSdkPort {
  final calls = <String>[];
  Object? updateError;
  Object? formError;
  Object? initError;
  Object? privacyError;
  bool canRequest = true;
  bool privacyRequired = false;
  Completer<void>? holdUpdate;
  void Function()? duringUpdate;

  /// Calls that reach the SDK or UMP in any way.
  int get sdkCalls => calls.length;

  @override
  Future<void> requestConsentInfoUpdate() async {
    calls.add('update');
    duringUpdate?.call();
    if (holdUpdate case final hold?) await hold.future;
    if (updateError case final e?) throw e;
  }

  @override
  Future<void> loadAndShowConsentFormIfRequired() async {
    calls.add('form');
    if (formError case final e?) throw e;
  }

  @override
  Future<bool> canRequestAds() async {
    calls.add('canRequest');
    return canRequest;
  }

  @override
  Future<bool> privacyOptionsRequired() async {
    calls.add('privacyRequired');
    return privacyRequired;
  }

  @override
  Future<void> showPrivacyOptionsForm() async {
    calls.add('privacyForm');
    if (privacyError case final e?) throw e;
  }

  @override
  Future<void> initialize() async {
    calls.add('initialize');
    if (initError case final e?) throw e;
  }
}

const _usable = AdsEnvironment(supportedPlatform: true, appIdConfigured: true);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => OraclyL10n.bind('tr'));
  tearDown(resetFeatureFlags);

  AdsGate gate(
    FakeAdsPort port,
    FakePremiumStatus premium, {
    AdsEnvironment environment = _usable,
    Duration stepTimeout = const Duration(seconds: 12),
  }) {
    final g = AdsGate(
      port: port,
      premium: premium,
      rolloutEnabled: () => AdsRollout.enabled,
      environment: environment,
      stepTimeout: stepTimeout,
    );
    addTearDown(g.dispose);
    return g;
  }

  group('rollout', () {
    test('ads_v1 is off by default and in the catalog', () {
      expect(ProductFeatureFlags.adsV1.defaultValue, isFalse);
      expect(ProductFeatureFlags.catalog, contains(ProductFeatureFlags.adsV1));
      expect(ProductFeatureFlags.defaults()['ads_v1'], isFalse);
      resetFeatureFlags();
      expect(AdsRollout.buildRolloutEnabled, isFalse);
      expect(AdsRollout.enabled, isFalse);
    });

    test('off: zero SDK calls, even for a verified free member', () async {
      resetFeatureFlags();
      final port = FakeAdsPort();
      final g = gate(port, MutablePremium());
      expect(await g.prepare(userInitiated: true), AdsGateStatus.off);
      expect(await g.showPrivacyOptions(), isFalse);
      expect(g.canRequestAds, isFalse);
      expect(port.sdkCalls, 0);
    });

    test('reading the provider never touches the SDK', () {
      setAdsFlag(true);
      final port = FakeAdsPort();
      final container = ProviderContainer(
        overrides: [
          adsSdkPortProvider.overrideWithValue(port),
          adsEnvironmentProvider.overrideWithValue(_usable),
          premiumStatusProvider.overrideWith((ref) => MutablePremium()),
        ],
      );
      addTearDown(container.dispose);
      final g = container.read(adsGateProvider);
      expect(g.status, AdsGateStatus.idle);
      expect(g.canRequestAds, isFalse);
      expect(port.sdkCalls, 0);
    });
  });

  group('environment', () {
    test('only Android / iOS, and a release only with a real app id', () {
      AdsEnvironment env({
        TargetPlatform platform = TargetPlatform.android,
        bool web = false,
        bool release = true,
        String android = '',
        String ios = '',
      }) => AdsEnvironment.resolve(
        platform: platform,
        web: web,
        releaseMode: release,
        androidReleaseAppId: android,
        iosReleaseAppId: ios,
      );

      expect(env(web: true).supportedPlatform, isFalse);
      expect(env(platform: TargetPlatform.windows).usable, isFalse);
      expect(env(release: false).usable, isTrue, reason: 'sample id, test ads');
      expect(env().usable, isFalse, reason: 'release without an id');
      expect(
        env(android: 'ca-app-pub-3940256099942544~3347511713').usable,
        isFalse,
        reason: 'Google sample id is never a release id',
      );
      expect(env(android: 'disabled').usable, isFalse);
      expect(
        env(android: 'ca-app-pub-1234567890123456~1234567890').usable,
        isTrue,
      );
      expect(
        env(
          platform: TargetPlatform.iOS,
          android: 'ca-app-pub-1234567890123456~1234567890',
        ).usable,
        isFalse,
        reason: 'each platform needs its own id',
      );
    });

    test('unsupported or unconfigured: zero SDK calls', () async {
      setAdsFlag(true);
      for (final (env, expected) in [
        (
          const AdsEnvironment(
            supportedPlatform: false,
            appIdConfigured: false,
          ),
          AdsGateStatus.unsupportedPlatform,
        ),
        (
          const AdsEnvironment(supportedPlatform: true, appIdConfigured: false),
          AdsGateStatus.notConfigured,
        ),
      ]) {
        final port = FakeAdsPort();
        final g = gate(port, MutablePremium(), environment: env);
        expect(await g.prepare(userInitiated: true), expected);
        expect(port.sdkCalls, 0);
      }
    });
  });

  group('membership', () {
    test('Premium: zero SDK calls, never ready', () async {
      setAdsFlag(true);
      final port = FakeAdsPort();
      final g = gate(port, MutablePremium(premium: true));
      expect(await g.prepare(userInitiated: true), AdsGateStatus.premium);
      expect(g.canRequestAds, isFalse);
      expect(port.sdkCalls, 0);
    });

    test(
      'not verified free (loading, busy, error, unverified, store unavailable): zero SDK calls',
      () async {
        setAdsFlag(true);
        for (final premium in [
          MutablePremium(loaded: false),
          MutablePremium(
            busy: true,
            entitlement: PremiumEntitlementState.pending,
          ),
          MutablePremium(
            entitlement: PremiumEntitlementState.restoring,
            busy: true,
          ),
          MutablePremium(entitlement: PremiumEntitlementState.error),
          MutablePremium(entitlement: PremiumEntitlementState.unverified),
          MutablePremium(entitlement: PremiumEntitlementState.unavailable),
        ]) {
          final port = FakeAdsPort();
          final g = gate(port, premium);
          expect(
            await g.prepare(userInitiated: true),
            AdsGateStatus.membershipUnknown,
            reason: '${premium.entitlement}',
          );
          expect(port.sdkCalls, 0, reason: '${premium.entitlement}');
        }
      },
    );

    test('becoming Premium while consent is pending: no SDK start', () async {
      setAdsFlag(true);
      final premium = MutablePremium();
      final port = FakeAdsPort()
        ..duringUpdate = () => premium.set(
          premium: true,
          entitlement: PremiumEntitlementState.active,
        );
      final g = gate(port, premium);
      expect(await g.prepare(), AdsGateStatus.premium);
      expect(port.calls, ['update']);
      expect(g.canRequestAds, isFalse);
    });

    test('a refresh to Premium after ready closes the gate at once', () async {
      setAdsFlag(true);
      final premium = MutablePremium();
      final port = FakeAdsPort();
      final g = gate(port, premium);
      expect(await g.prepare(), AdsGateStatus.ready);
      expect(g.canRequestAds, isTrue);
      premium.set(premium: true, entitlement: PremiumEntitlementState.active);
      expect(g.status, AdsGateStatus.premium);
      expect(g.canRequestAds, isFalse);
      // Lapsing back to free does not silently reopen: a new prepare is needed.
      premium.set(
        premium: false,
        entitlement: PremiumEntitlementState.inactive,
      );
      expect(g.canRequestAds, isFalse);
    });

    test(
      'a membership read that turns into an error closes the gate',
      () async {
        setAdsFlag(true);
        final premium = MutablePremium();
        final g = gate(FakeAdsPort(), premium);
        await g.prepare();
        premium.set(entitlement: PremiumEntitlementState.error);
        expect(g.status, AdsGateStatus.membershipUnknown);
        expect(g.canRequestAds, isFalse);
      },
    );

    test(
      'turning the flag off after ready closes the gate without a call',
      () async {
        setAdsFlag(true);
        final port = FakeAdsPort();
        final g = gate(port, MutablePremium());
        await g.prepare();
        final before = port.sdkCalls;
        setAdsFlag(false);
        expect(g.canRequestAds, isFalse);
        expect(port.sdkCalls, before);
      },
    );
  });

  group('consent and SDK', () {
    test(
      'verified free + consent: update, then UMP verdict, then one SDK start',
      () async {
        setAdsFlag(true);
        final port = FakeAdsPort();
        final g = gate(port, MutablePremium());
        expect(await g.prepare(), AdsGateStatus.ready);
        expect(port.calls, [
          'update',
          'privacyRequired',
          'canRequest',
          'initialize',
        ]);
        expect(g.canRequestAds, isTrue);
        await g.prepare();
        expect(port.calls.where((c) => c == 'initialize'), hasLength(1));
      },
    );

    test('the consent form only appears from a user-started moment', () async {
      setAdsFlag(true);
      final quiet = FakeAdsPort();
      await gate(quiet, MutablePremium()).prepare();
      expect(quiet.calls, isNot(contains('form')));
      final asked = FakeAdsPort();
      await gate(asked, MutablePremium()).prepare(userInitiated: true);
      expect(asked.calls.indexOf('form'), 1);
    });

    test('consent refresh failure (network): no ads, no SDK start', () async {
      setAdsFlag(true);
      final port = FakeAdsPort()
        ..updateError = const SocketException('offline');
      final g = gate(port, MutablePremium());
      expect(await g.prepare(userInitiated: true), AdsGateStatus.consentFailed);
      expect(port.calls, ['update']);
      expect(g.canRequestAds, isFalse);
    });

    test('consent refresh that never answers times out closed', () async {
      setAdsFlag(true);
      final port = FakeAdsPort()..holdUpdate = Completer<void>();
      final g = gate(
        port,
        MutablePremium(),
        stepTimeout: const Duration(milliseconds: 20),
      );
      expect(await g.prepare(), AdsGateStatus.consentFailed);
      expect(port.calls, isNot(contains('initialize')));
    });

    test('consent form error: no ads, no SDK start', () async {
      setAdsFlag(true);
      final port = FakeAdsPort()
        ..formError = const AdsSdkException('consent_form', '2');
      expect(
        await gate(port, MutablePremium()).prepare(userInitiated: true),
        AdsGateStatus.consentFailed,
      );
      expect(port.calls, isNot(contains('initialize')));
    });

    test('consent not granted: no SDK start', () async {
      setAdsFlag(true);
      final port = FakeAdsPort()..canRequest = false;
      final g = gate(port, MutablePremium());
      expect(
        await g.prepare(userInitiated: true),
        AdsGateStatus.consentNotGranted,
      );
      expect(port.calls, isNot(contains('initialize')));
      expect(g.canRequestAds, isFalse);
    });

    test(
      'SDK start failure: the app carries on, the gate stays closed',
      () async {
        setAdsFlag(true);
        final port = FakeAdsPort()
          ..initError = const AdsSdkException('initialize', 'boom');
        final g = gate(port, MutablePremium());
        expect(await g.prepare(), AdsGateStatus.sdkFailed);
        expect(g.canRequestAds, isFalse);
      },
    );

    test('concurrent prepares share one run', () async {
      setAdsFlag(true);
      final port = FakeAdsPort()..holdUpdate = Completer<void>();
      final g = gate(port, MutablePremium());
      final a = g.prepare();
      final b = g.prepare();
      port.holdUpdate!.complete();
      expect(await a, AdsGateStatus.ready);
      expect(await b, AdsGateStatus.ready);
      expect(port.calls.where((c) => c == 'update'), hasLength(1));
    });

    test('withdrawing consent in privacy options closes the gate', () async {
      setAdsFlag(true);
      final port = FakeAdsPort()..privacyRequired = true;
      final g = gate(port, MutablePremium());
      await g.prepare();
      expect(g.privacyOptionsRequired, isTrue);
      port.canRequest = false;
      expect(await g.showPrivacyOptions(), isTrue);
      expect(g.status, AdsGateStatus.consentNotGranted);
      expect(g.canRequestAds, isFalse);
    });

    test('privacy options failure is reported, not thrown', () async {
      setAdsFlag(true);
      final port = FakeAdsPort()
        ..privacyError = const AdsSdkException('privacy_options');
      expect(await gate(port, MutablePremium()).showPrivacyOptions(), isFalse);
    });
  });

  group('account switch', () {
    test('a new account gets a fresh, unprepared gate', () async {
      setAdsFlag(true);
      final port = FakeAdsPort();
      final container = ProviderContainer(
        overrides: [
          adsSdkPortProvider.overrideWithValue(port),
          adsEnvironmentProvider.overrideWithValue(_usable),
          premiumStatusProvider.overrideWith((ref) => MutablePremium()),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(adsGateProvider, (_, _) {});
      addTearDown(sub.close);
      final first = container.read(adsGateProvider);
      expect(await first.prepare(), AdsGateStatus.ready);
      UserLocalDataIsolation.accountSwitchEpoch.value++;
      final second = container.read(adsGateProvider);
      expect(identical(first, second), isFalse);
      expect(second.status, AdsGateStatus.idle);
      expect(second.canRequestAds, isFalse);
    });
  });

  group('privacy options entry', () {
    Future<void> pumpTile(WidgetTester tester, FakeAdsPort port) async {
      final container = ProviderContainer(
        overrides: [
          adsSdkPortProvider.overrideWithValue(port),
          adsEnvironmentProvider.overrideWithValue(_usable),
          premiumStatusProvider.overrideWith((ref) => MutablePremium()),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: AdsPrivacyOptionsTile()),
          ),
        ),
      );
      if (AdsRollout.enabled) {
        await tester.runAsync(() => container.read(adsGateProvider).prepare());
      }
      await tester.pump();
    }

    testWidgets('flag off: nothing on screen, no call', (tester) async {
      resetFeatureFlags();
      final port = FakeAdsPort()..privacyRequired = true;
      await pumpTile(tester, port);
      expect(
        find.text(OraclyL10n.t('ads.privacy_options.title')),
        findsNothing,
      );
      expect(port.sdkCalls, 0);
    });

    testWidgets('flag on + UMP requires it: the entry opens the form', (
      tester,
    ) async {
      setAdsFlag(true);
      final port = FakeAdsPort()..privacyRequired = true;
      await pumpTile(tester, port);
      expect(
        find.text(OraclyL10n.t('ads.privacy_options.title')),
        findsOneWidget,
      );
      await tester.tap(find.text(OraclyL10n.t('ads.privacy_options.title')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      expect(port.calls, contains('privacyForm'));
    });

    testWidgets('flag on, not required: nothing on screen', (tester) async {
      setAdsFlag(true);
      await pumpTile(tester, FakeAdsPort());
      expect(
        find.text(OraclyL10n.t('ads.privacy_options.title')),
        findsNothing,
      );
    });

    test('TR / EN / RU copy exists', () {
      for (final locale in ['tr', 'en', 'ru']) {
        OraclyL10n.bind(locale);
        for (final key in [
          'ads.privacy_options.title',
          'ads.privacy_options.subtitle',
          'ads.privacy_options.failed',
        ]) {
          expect(OraclyL10n.t(key), isNot(key), reason: '$locale $key');
        }
      }
    });
  });

  group('boundaries', () {
    String read(String path) =>
        File(path).readAsStringSync().replaceAll('\r\n', '\n');
    Iterable<File> dart(String dir) => Directory(dir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    test('only the port talks to google_mobile_ads; no ad is ever loaded', () {
      final importers = [
        for (final f in dart('lib'))
          if (read(f.path).contains('package:google_mobile_ads/'))
            f.path.replaceAll('\\', '/'),
      ];
      expect(importers, [
        'lib/features/ads/services/google_mobile_ads_port.dart',
      ]);
      final port = read(importers.single);
      for (final call in [
        '.load(',
        'Ad.load',
        'loadAd',
        'RequestConfiguration(testDeviceIds',
      ]) {
        expect(port, isNot(contains(call)), reason: call);
      }
    });

    test('the daily free reading allowance never depends on ads', () {
      for (final f in [
        ...dart('lib/features/reading_access'),
        ...dart('lib/features/reading_commerce'),
      ]) {
        expect(read(f.path), isNot(contains('features/ads/')), reason: f.path);
        expect(read(f.path), isNot(contains('/ads/')), reason: f.path);
      }
      for (final f in dart('lib/features/ads')) {
        expect(read(f.path), isNot(contains('reading_access')), reason: f.path);
      }
    });

    test('nothing prepares the gate yet (no placement, nothing at launch)', () {
      final callers = [
        for (final f in dart('lib'))
          if (!f.path.replaceAll('\\', '/').contains('lib/features/ads/') &&
              read(f.path).contains('.prepare('))
            f.path,
      ];
      expect(
        callers.where((p) => read(p).contains('adsGateProvider')),
        isEmpty,
      );
    });

    test('no App Tracking Transparency prompt is requested', () {
      expect(
        read('ios/Runner/Info.plist'),
        isNot(contains('NSUserTrackingUsageDescription')),
      );
      expect(
        read('pubspec.yaml'),
        isNot(contains('app_tracking_transparency')),
      );
      for (final f in dart('lib')) {
        expect(
          read(f.path),
          isNot(contains('requestTrackingAuthorization')),
          reason: f.path,
        );
      }
    });
  });

  group('platform configuration', () {
    String read(String path) =>
        File(path).readAsStringSync().replaceAll('\r\n', '\n');

    test('SDK pinned exactly', () {
      expect(read('pubspec.yaml'), contains('  google_mobile_ads: 9.1.0\n'));
      expect(read('pubspec.lock'), contains('version: "9.1.0"'));
    });

    test('Android: app id placeholder, delayed measurement, ad ids kept out', () {
      final manifest = read('android/app/src/main/AndroidManifest.xml');
      expect(
        manifest,
        contains(
          'android:name="com.google.android.gms.ads.APPLICATION_ID"\n            android:value="\${admobAppId}"',
        ),
      );
      expect(
        manifest,
        contains(
          'android:name="com.google.android.gms.ads.DELAY_APP_MEASUREMENT_INIT"\n            android:value="true"',
        ),
      );
      for (final permission in [
        'com.google.android.gms.permission.AD_ID',
        'android.permission.ACCESS_ADSERVICES_AD_ID',
        'android.permission.ACCESS_ADSERVICES_ATTRIBUTION',
        'android.permission.ACCESS_ADSERVICES_TOPICS',
      ]) {
        expect(
          RegExp(
            'android:name="${RegExp.escape(permission)}"\\s*tools:node="remove"',
          ).hasMatch(manifest),
          isTrue,
          reason: permission,
        );
      }
    });

    test(
      'Android: sample id only outside release; release refuses without a real id',
      () {
        final gradle = read('android/app/build.gradle.kts');
        expect(
          gradle,
          contains('manifestPlaceholders["admobAppId"] = admobSampleAppId'),
        );
        expect(
          gradle,
          contains(
            'manifestPlaceholders["admobAppId"] = admobReleaseAppId ?: ""',
          ),
        );
        expect(
          gradle,
          contains(
            'if (releaseRequested && !isRealAdmobAppId(admobReleaseAppId))',
          ),
        );
        expect(
          gradle,
          contains('!id.startsWith("ca-app-pub-3940256099942544")'),
        );
        // Exactly one sample id literal, and it is the defaultConfig one.
        expect('ca-app-pub-3940256099942544~'.allMatches(gradle), hasLength(1));
      },
    );

    test('iOS: sample id in Debug only, Release guarded, measurement delayed', () {
      final plist = read('ios/Runner/Info.plist');
      expect(
        plist,
        contains(
          '<key>GADApplicationIdentifier</key>\n\t<string>\$(ORACLY_ADMOB_APP_ID)</string>',
        ),
      );
      expect(
        plist,
        contains('<key>GADDelayAppMeasurementInit</key>\n\t<true/>'),
      );
      expect(
        read('ios/Flutter/Debug.xcconfig'),
        contains('ORACLY_ADMOB_APP_ID=ca-app-pub-3940256099942544~1458002511'),
      );
      final release = read('ios/Flutter/Release.xcconfig');
      expect(release, contains('ORACLY_ADMOB_APP_ID=disabled'));
      expect(release, contains('#include? "AdMobApp.xcconfig"'));
      expect(release, isNot(contains('3940256099942544')));
      expect(read('ios/.gitignore'), contains('Flutter/AdMobApp.xcconfig'));
      final pbx = read('ios/Runner.xcodeproj/project.pbxproj');
      expect(
        pbx,
        contains(
          r'shellScript = "/bin/sh \"$SRCROOT/scripts/admob_app_id_guard.sh\" && /bin/sh \"$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh\" build";',
        ),
      );
    });

    test('iOS guard: Debug passes; Release/Profile need a real id', () async {
      final sh = Platform.isWindows
          ? r'C:\Program Files\Git\bin\sh.exe'
          : '/bin/sh';
      if (!File(sh).existsSync()) {
        markTestSkipped('no POSIX shell');
        return;
      }
      Future<int> run(String configuration, String id) async =>
          (await Process.run(
            sh,
            ['ios/scripts/admob_app_id_guard.sh'],
            environment: {
              'CONFIGURATION': configuration,
              'ORACLY_ADMOB_APP_ID': id,
            },
          )).exitCode;
      expect(await run('Debug', 'ca-app-pub-3940256099942544~1458002511'), 0);
      expect(await run('Release', 'disabled'), 1);
      expect(await run('Release', ''), 1);
      expect(await run('Release', 'ca-app-pub-3940256099942544~1458002511'), 1);
      expect(await run('Profile', 'disabled'), 1);
      expect(await run('Release', 'ca-app-pub-123~1'), 1);
      expect(await run('Release', 'ca-app-pub-1234567890123456~1234567890'), 0);
    });
  });
}
