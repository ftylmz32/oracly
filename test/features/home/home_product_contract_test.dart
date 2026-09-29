import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/constants/app_assets.dart';
import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/modules/oracly_feature_id.dart';
import 'package:oracly_new/core/modules/oracly_feature_navigation.dart';
import 'package:oracly_new/core/modules/oracly_feature_registry.dart';
import 'package:oracly_new/core/services/premium_service.dart';
import 'package:oracly_new/features/home/copy/home_discovery_copy.dart';
import 'package:oracly_new/features/home/master/home_master_composition.dart';
import 'package:oracly_new/features/home/reference/home_discovery_module_arts.dart';
import 'package:oracly_new/features/home/reference/home_reference_modules.dart';
import 'package:oracly_new/features/home/reference/home_reference_premium_copy.dart';
import 'package:oracly_new/features/home/reference/home_viewport_layout.dart';
import 'package:oracly_new/features/premium/controllers/premium_status_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const doors = <(OraclyFeatureId, String, String)>[
    (OraclyFeatureId.coffee, AppAssets.homeCoffee, 'Kahve Falı'),
    (OraclyFeatureId.palm, AppAssets.homePalm, 'El Falı'),
    (OraclyFeatureId.astrology, AppAssets.homeAstrology, 'Astroloji'),
    (OraclyFeatureId.starMap, AppAssets.homeYildizname, 'Yıldızname'),
    (OraclyFeatureId.soulMate, AppAssets.homeSoulMate, 'Ruh Eşi'),
    (OraclyFeatureId.tarot, AppAssets.homeTarot, 'Tarot'),
    (OraclyFeatureId.dream, AppAssets.homeDream, 'Rüya Analizi'),
  ];

  setUp(() => OraclyL10n.bind('tr'));

  test('each live Home door maps id, art, title, and navigation', () {
    final specs = [
      ...HomeReferenceModules.list(),
      HomeReferenceModules.dreamExtension,
    ];
    expect(specs.map((spec) => spec.id), doors.map((door) => door.$1));
    for (var i = 0; i < doors.length; i++) {
      final spec = specs[i];
      final door = doors[i];
      final module = OraclyFeatureRegistry.byId(spec.id);
      expect(module, isNotNull);
      expect(module!.isLive, isTrue);
      expect(module.isPreview, isFalse);
      expect(HomeDiscoveryModuleArt.assetFor(spec.visual), door.$2);
      expect(HomeDiscoveryCopy.title(spec.id), door.$3);
      expect(OraclyFeatureNavigation.canOpen(spec.id), isTrue);
    }
    final soul = OraclyFeatureRegistry.byId(OraclyFeatureId.soulMate)!;
    expect(soul.requiresPremium, isTrue);
    expect(
      HomeReferenceModules.list().singleWhere((m) => m.id == soul.id).premiumMark,
      isTrue,
    );
    expect(
      HomeReferenceModules.list(quietPremium: true)
          .singleWhere((m) => m.id == soul.id)
          .premiumMark,
      isFalse,
    );
    expect(HomeReferenceModules.dreamExtension.isNew, isFalse);
  });

  test('optional Home cards participate in the scroll decision', () {
    const hint = 1400.0;
    const nav = 118.0;
    final preferred = HomeViewportLayout.resolve(hint).preferredContentHeight;
    final body = preferred + nav + 8;
    final plain = HomeMasterComposition.resolve(
      bodyHeight: body,
      navClearance: nav,
      screenHeightHint: hint,
    );
    final crowded = HomeMasterComposition.resolve(
      bodyHeight: body,
      navClearance: nav,
      screenHeightHint: hint,
      extraContentHeight: HomeMasterComposition.continueSlot +
          HomeMasterComposition.nextActionSlot,
    );
    expect(plain.requiresScroll, isFalse);
    expect(crowded.requiresScroll, isTrue);
  });

  test('unloaded Premium copy does not claim a finished store state', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    final status = PremiumStatusController(
      PremiumService(
        MockPremiumRepository(storage),
        MockUserRepository(storage),
      ),
    );
    expect(status.loaded, isFalse);
    expect(
      HomeReferencePremiumCopy.resolve(status).body,
      PremiumCopy.loadingBody,
    );
    await status.load();
    expect(status.loaded, isTrue);
    expect(status.isPremium, isFalse);
    expect(
      HomeReferencePremiumCopy.resolve(status).body,
      PremiumCopy.ctaUnavailable,
    );
  });

  test('live Home discovery copy exists in Turkish, English, and Russian', () {
    const keys = <String>[
      'home.discoveries_band',
      'home.discoveries.see_all',
      'home.or_flagship.title',
      'home.or_flagship.cta',
      'home.today_moment',
    ];
    for (final code in ['tr', 'en', 'ru']) {
      OraclyL10n.bind(code);
      for (final door in doors) {
        final title = HomeDiscoveryCopy.title(door.$1);
        expect(title, isNotEmpty);
        expect(title.contains('home.'), isFalse);
      }
      for (final key in keys) {
        final value = OraclyL10n.t(key);
        expect(value, isNotEmpty);
        expect(value, isNot(key));
      }
    }
  });
}
