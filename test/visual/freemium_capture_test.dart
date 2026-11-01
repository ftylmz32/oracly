/// Renders the real Freemium V1 surfaces in their real chambers — the
/// Coffee V3 intro in the Coffee chamber, the Palm landing in the Palm
/// chamber, the Premium screen, the Fincan Haritası door and map — with
/// real fonts, and (only when FREEMIUM_CAPTURE_DIR is set) writes PNGs.
/// "before_*" frames are the same surfaces with the rollout flag off.
/// Membership states come from a fake status (no store, no purchase);
/// cup photos come from CUP_MAP_PHOTO_DIR or the repo fixture.
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/design_system/app_layout.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/coffee/coffee_v3/presentation/coffee_v3_intro_view.dart';
import 'package:oracly_new/features/coffee/cup_map/models/coffee_cup_map_record.dart';
import 'package:oracly_new/features/coffee/cup_map/presentation/coffee_cup_map_canvas.dart';
import 'package:oracly_new/features/coffee/cup_map/presentation/coffee_cup_map_entry.dart';
import 'package:oracly_new/features/coffee/cup_map/presentation/coffee_cup_map_screen.dart';
import 'package:oracly_new/features/coffee/cup_map/providers/coffee_cup_map_providers.dart';
import 'package:oracly_new/features/coffee/cup_map/services/coffee_cup_map_consent.dart';
import 'package:oracly_new/features/coffee/cup_map/services/coffee_cup_map_photo_archive.dart';
import 'package:oracly_new/features/coffee/cup_map/services/coffee_cup_map_store.dart';
import 'package:oracly_new/features/coffee/coffee_v3/models/coffee_v3_photo_slot.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_landing_chamber.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_reference_atmosphere.dart';
import 'package:oracly_new/features/palm/copy/palm_copy.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/presentation/palm_atmosphere.dart';
import 'package:oracly_new/features/palm/presentation/palm_landing_view.dart';
import 'package:oracly_new/features/palm/presentation/palm_reference_app_bar.dart';
import 'package:oracly_new/features/palm/presentation/palm_tokens.dart';
import 'package:oracly_new/features/premium/models/premium_entitlement_state.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_reference_screen.dart';
import 'package:oracly_new/features/premium/providers/premium_providers.dart';
import 'package:oracly_new/features/reading_access/copy/freemium_copy.dart';
import 'package:oracly_new/features/reading_access/models/reading_allowance.dart';
import 'package:oracly_new/features/reading_access/presentation/coffee_allowance_panel.dart';
import 'package:oracly_new/features/reading_access/presentation/palm_allowance_line.dart';
import 'package:oracly_new/features/reading_commerce/models/reading_commerce_view.dart';
import 'package:oracly_new/features/reading_commerce/presentation/reading_commerce_screen.dart';
import 'package:oracly_new/shared/widgets/oracly_scaffold.dart';

import '../support/coffee_cup_map_test_support.dart';
import '../support/freemium_test_support.dart';
import '../support/layout_fonts.dart';

final _captureDir = Platform.environment['FREEMIUM_CAPTURE_DIR'];
final _photoDir = Platform.environment['CUP_MAP_PHOTO_DIR'];
final _boundary = GlobalKey();
const _reading = 'coffee-v3-freemium-capture';
const _phone = Size(390, 844);

Future<void> _capture(WidgetTester tester, String name) async {
  final dir = _captureDir;
  if (dir == null) return;
  await tester.runAsync(() async {
    final boundary =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory(dir).createSync(recursive: true);
    File('$dir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

String _sourceFor(CoffeeV3PhotoSlot slot) {
  final dir = _photoDir;
  if (dir != null) {
    final path = '$dir/${slot.wireValue}.jpg';
    if (File(path).existsSync()) return path;
  }
  return cupMapFixturePhoto;
}

ReadingAllowanceView _view(
  ReadingAllowanceKind kind,
  ReadingAllowanceStatus status, {
  bool premium = false,
}) => ReadingAllowanceView(kind: kind, status: status, premium: premium);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late CoffeeCupMapStore store;
  late CoffeeCupMapConsent consent;
  late LocalStorage storage;
  late List<CoffeeCupMapPhoto> photos;

  setUpAll(loadLayoutFonts);

  setUp(() async {
    OraclyL10n.bind('tr');
    setFreemiumFlag(true);
    // C: is full on this machine; scratch files live on D:.
    final root = Directory('D:/oracly_fincan_tmp/freemium_capture_tmp')
      ..createSync(recursive: true);
    temp = root.createTempSync('run_');
    await installCupMapPaths(temp);
    storage = await ownedStorage('owner-freemium-capture');
    store = CoffeeCupMapStore(storage);
    consent = CoffeeCupMapConsent(storage);
    photos = [
      for (final slot in coffeeV3CanonicalSlotOrder)
        CoffeeCupMapPhoto(
          slot: slot,
          path: await CoffeeCupMapPhotoArchive.persist(
            readingId: '${_reading}_cupmap_${slot.wireValue}',
            sourcePath: _sourceFor(slot),
          ),
          sha256: 'capture',
        ),
    ];
    await store.createIfAbsent(
      ownerId: 'owner-freemium-capture',
      readingId: _reading,
      photos: photos,
    );
    await store.addPin(
      readingId: _reading,
      slot: CoffeeV3PhotoSlot.cupViewA,
      x: 0.36,
      y: 0.42,
      note: 'Sapın karşısındaki koyu kıvrım',
    );
    await store.addPin(
      readingId: _reading,
      slot: CoffeeV3PhotoSlot.cupViewA,
      x: 0.62,
      y: 0.58,
    );
  });

  tearDown(() async {
    resetFeatureFlags();
    imageCache.clear();
    try {
      if (await temp.exists()) await temp.delete(recursive: true);
    } catch (_) {
      // A decoded photo may still hold its file on Windows; scratch only.
    }
  });

  Future<void> frames(WidgetTester tester, int n) async {
    for (var i = 0; i < n; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    Size size = _phone,
    double textScale = 1,
    FakePremiumStatus? premium,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    // Decode the kept photos first (file images never finish inside fake
    // async on their own).
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final context = tester.element(find.byType(SizedBox));
    await tester.runAsync(() async {
      for (final photo in photos) {
        if (!File(photo.path).existsSync()) continue;
        await precacheImage(coffeeCupMapPhotoImage(photo.path), context);
        await precacheImage(
          ResizeImage(FileImage(File(photo.path)), width: 240),
          context,
        );
      }
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          premiumStatusProvider.overrideWith(
            (ref) => premium ?? FakePremiumStatus(),
          ),
          localStorageProvider.overrideWithValue(storage),
          coffeeCupMapStoreProvider.overrideWithValue(store),
          coffeeCupMapConsentProvider.overrideWithValue(consent),
        ],
        child: RepaintBoundary(
          key: _boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: robotoDarkTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScale),
                // Stills of settled layouts; the motion contract is tested
                // elsewhere.
                disableAnimations: true,
                padding: const EdgeInsets.only(top: 47, bottom: 34),
              ),
              child: child!,
            ),
            home: home,
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 120)),
    );
    await frames(tester, 16);
    expect(tester.takeException(), isNull);
  }

  Widget coffeeIntro(ReadingAllowanceView? view, {bool original = false}) {
    final Widget? allowance = view == null
        ? null
        : view.canStart
        ? CoffeeAllowancePanel(view: view)
        : CoffeeAllowanceUsedCard(view: view, onRecheck: () {});
    return CoffeeLandingChamber(
      onBack: () {},
      child: CoffeeV3IntroView(
        ctaLabel: original ? null : FreemiumCopy.coffeeCta,
        onStart: view == null || view.canStart ? () {} : null,
        allowance: allowance,
      ),
    );
  }

  /// The Palm chamber as PalmReferenceScreen lays it out.
  Widget palmChamber(Widget body) {
    return Builder(
      builder: (context) => OraclyScaffold(
        safeArea: false,
        backgroundOverlay: const PalmAtmosphere(child: SizedBox.shrink()),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              PalmTokens.screenHorizontal,
              PalmTokens.screenTop,
              PalmTokens.screenHorizontal,
              AppLayout.scrollBottomInset(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PalmReferenceAppBar(onBack: () {}),
                SizedBox(height: PalmTokens.gap),
                Expanded(child: body),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget palmLanding(ReadingAllowanceView? view) => palmChamber(
    PalmLandingView(
      hand: PalmHand.right,
      onHand: (_) {},
      onCamera: () {},
      onGallery: () {},
      allowance: view == null ? null : PalmAllowanceLine(view: view),
    ),
  );

  Widget palmUsed(ReadingAllowanceView view) => palmChamber(
    PalmAllowanceUsedView(view: view, onRecheck: () {}, onBack: () {}),
  );

  /// A result screen's tail: the door sits under the reading.
  Widget resultTail() => OraclyScaffold(
    safeArea: false,
    backgroundOverlay: const CoffeeReferenceAtmosphere(child: SizedBox.shrink()),
    child: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: const CoffeeCupMapEntry(readingId: _reading),
      ),
    ),
  );

  /// Brings [text] into view, [alignment] down from the top of the scroll.
  Future<void> scrollToText(
    WidgetTester tester,
    String text, {
    double alignment = 0.5,
  }) async {
    final target = find.text(text).first;
    await tester.runAsync(() async {});
    Scrollable.ensureVisible(tester.element(target), alignment: alignment);
    await frames(tester, 6);
  }

  // Every Freemium surface at 320 / 360 / 390 px and 1x / 2x text. (The
  // shipped Palm landing without the line overflows at 320 and 360 px with
  // 2x text; that existing layout is unchanged here and reported.)
  group('no overflow (rollout on)', () {
    for (final width in [320.0, 360.0, 390.0]) {
      for (final scale in [1.0, 2.0]) {
      for (final variant in ['palm_free', 'palm_used', 'coffee_free', 'coffee_used', 'door', 'premium']) {
        testWidgets('$variant ${width.toInt()} px x$scale', (tester) async {
          final size = Size(width, width == 320 ? 640 : (width == 360 ? 740 : 844));
          final home = switch (variant) {
            'palm_free' => palmLanding(_view(ReadingAllowanceKind.palm, ReadingAllowanceStatus.free)),
            'palm_used' => palmUsed(_view(ReadingAllowanceKind.palm, ReadingAllowanceStatus.usedToday)),
            'coffee_free' => coffeeIntro(_view(ReadingAllowanceKind.coffee, ReadingAllowanceStatus.free)),
            'coffee_used' => coffeeIntro(_view(ReadingAllowanceKind.coffee, ReadingAllowanceStatus.usedToday)),
            'door' => resultTail(),
            _ => const PremiumReferenceScreen(),
          };
          await pump(tester, home, size: size, textScale: scale);
        });
      }
      }
    }
  });

  group('after (rollout on)', () {
    testWidgets('01 free Coffee intro', (tester) async {
      await pump(tester, coffeeIntro(_view(ReadingAllowanceKind.coffee, ReadingAllowanceStatus.free)));
      await scrollToText(tester, FreemiumCopy.coffeeCta);
      await _capture(tester, '01_coffee_free_intro');
    });

    testWidgets('02 free Palm landing', (tester) async {
      await pump(tester, palmLanding(_view(ReadingAllowanceKind.palm, ReadingAllowanceStatus.free)));
      await _capture(tester, '02_palm_free_landing');
    });

    testWidgets('03 Coffee used today', (tester) async {
      await pump(tester, coffeeIntro(_view(ReadingAllowanceKind.coffee, ReadingAllowanceStatus.usedToday)));
      await scrollToText(tester, FreemiumCopy.recheck);
      await _capture(tester, '03_coffee_used_today');
    });

    testWidgets('04 Palm used today', (tester) async {
      await pump(tester, palmUsed(_view(ReadingAllowanceKind.palm, ReadingAllowanceStatus.usedToday)));
      await _capture(tester, '04_palm_used_today');
    });

    testWidgets('04b Palm used today, Premium member', (tester) async {
      await pump(
        tester,
        palmUsed(_view(ReadingAllowanceKind.palm, ReadingAllowanceStatus.usedToday, premium: true)),
        premium: FakePremiumStatus(premium: true),
      );
      await _capture(tester, '04b_palm_used_today_premium');
    });

    testWidgets('05 Premium Coffee', (tester) async {
      await pump(
        tester,
        coffeeIntro(_view(ReadingAllowanceKind.coffee, ReadingAllowanceStatus.premium, premium: true)),
        premium: FakePremiumStatus(premium: true),
      );
      await scrollToText(tester, FreemiumCopy.coffeeCta);
      await _capture(tester, '05_coffee_premium');
    });

    testWidgets('06 Premium Palm', (tester) async {
      await pump(
        tester,
        palmLanding(_view(ReadingAllowanceKind.palm, ReadingAllowanceStatus.premium, premium: true)),
        premium: FakePremiumStatus(premium: true),
      );
      await _capture(tester, '06_palm_premium');
    });

    testWidgets('07 Premium screen, daily rights', (tester) async {
      await pump(tester, const PremiumReferenceScreen());
      await _capture(tester, '07a_premium_screen_top');
      await scrollToText(tester, FreemiumCopy.premiumSectionTitle, alignment: 0.08);
      await _capture(tester, '07b_premium_daily_rights');
    });

    testWidgets('07c Premium screen, member', (tester) async {
      await pump(tester, const PremiumReferenceScreen(), premium: FakePremiumStatus(premium: true));
      await scrollToText(tester, FreemiumCopy.premiumSectionTitle, alignment: 0.08);
      await _capture(tester, '07c_premium_daily_rights_member');
    });

    testWidgets('08 Fincan Haritası locked door', (tester) async {
      await pump(tester, resultTail());
      await _capture(tester, '08_cup_map_premium_lock');
    });

    testWidgets('08b Fincan Haritası while membership loads', (tester) async {
      await pump(tester, resultTail(), premium: FakePremiumStatus(loaded: false));
      await _capture(tester, '08b_cup_map_checking');
    });

    testWidgets('09 Fincan Haritası for a member', (tester) async {
      final premium = FakePremiumStatus(premium: true);
      await pump(tester, resultTail(), premium: premium);
      await _capture(tester, '09a_cup_map_member_door');
      await pump(tester, const CoffeeCupMapScreen(readingId: _reading), premium: premium);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await frames(tester, 20);
      await _capture(tester, '09b_cup_map_member_open');
    });

    testWidgets('10 membership could not be confirmed', (tester) async {
      final failed = FakePremiumStatus(entitlement: PremiumEntitlementState.error);
      await pump(
        tester,
        coffeeIntro(_view(ReadingAllowanceKind.coffee, ReadingAllowanceStatus.checkFailed)),
        premium: failed,
      );
      await scrollToText(tester, FreemiumCopy.retry);
      await _capture(tester, '10a_coffee_check_failed');
      await pump(
        tester,
        palmLanding(_view(ReadingAllowanceKind.palm, ReadingAllowanceStatus.checkFailed)),
        premium: failed,
      );
      await _capture(tester, '10b_palm_check_failed');
      await pump(tester, resultTail(), premium: failed);
      await _capture(tester, '10c_cup_map_check_failed');
    });

    for (final width in [320.0, 360.0, 390.0]) {
      final tag = switch (width) { 320 => '11', 360 => '13', _ => '12' };
      testWidgets('$tag ${width.toInt()} px, 2x text', (tester) async {
        final size = Size(width, switch (width) { 320 => 640.0, 360 => 740.0, _ => 844.0 });
        await pump(
          tester,
          coffeeIntro(_view(ReadingAllowanceKind.coffee, ReadingAllowanceStatus.free)),
          size: size,
          textScale: 2,
        );
        await scrollToText(tester, FreemiumCopy.freeTitle(ReadingAllowanceKind.coffee));
        await _capture(tester, '${tag}a_coffee_free_${width.toInt()}_2x');
        await scrollToText(tester, FreemiumCopy.coffeeCta);
        await _capture(tester, '${tag}b_coffee_free_cta_${width.toInt()}_2x');
        await pump(
          tester,
          coffeeIntro(_view(ReadingAllowanceKind.coffee, ReadingAllowanceStatus.usedToday)),
          size: size,
          textScale: 2,
        );
        await scrollToText(tester, FreemiumCopy.usedBody);
        await _capture(tester, '${tag}c_coffee_used_${width.toInt()}_2x');
        await pump(
          tester,
          palmLanding(_view(ReadingAllowanceKind.palm, ReadingAllowanceStatus.free)),
          size: size,
          textScale: 2,
        );
        await _capture(tester, '${tag}d_palm_free_${width.toInt()}_2x');
        await scrollToText(
          tester,
          FreemiumCopy.freeTitle(ReadingAllowanceKind.palm),
          alignment: 0.35,
        );
        await _capture(tester, '${tag}d2_palm_free_line_${width.toInt()}_2x');
        await scrollToText(tester, PalmCopy.galleryLabel, alignment: 0.9);
        await _capture(tester, '${tag}d3_palm_camera_cta_${width.toInt()}_2x');
        await pump(
          tester,
          palmUsed(_view(ReadingAllowanceKind.palm, ReadingAllowanceStatus.usedToday)),
          size: size,
          textScale: 2,
        );
        await _capture(tester, '${tag}e_palm_used_${width.toInt()}_2x');
        await pump(tester, resultTail(), size: size, textScale: 2);
        await _capture(tester, '${tag}f_cup_map_lock_${width.toInt()}_2x');
        await pump(tester, const PremiumReferenceScreen(), size: size, textScale: 2);
        await scrollToText(tester, FreemiumCopy.premiumHeroLead, alignment: 0.5);
        await _capture(tester, '${tag}h_premium_hero_${width.toInt()}_2x');
        await scrollToText(tester, FreemiumCopy.premiumSectionTitle, alignment: 0.05);
        await _capture(tester, '${tag}g_premium_rights_${width.toInt()}_2x');
      });
    }
  });

  group('before (rollout off)', () {
    setUp(() => setFreemiumFlag(false));

    testWidgets('Coffee V3 intro as shipped', (tester) async {
      await pump(tester, coffeeIntro(null, original: true));
      await scrollToText(tester, 'Başlayalım');
      await _capture(tester, 'before_01_coffee_intro');
    });

    testWidgets('Palm entry as shipped (credit screen first)', (tester) async {
      await pump(
        tester,
        palmChamber(
          ReadingCommerceScreen(
            view: ReadingCommerceView.closed(),
            embedded: true,
            focus: ReadingCommerceFocus.palm,
            onContinue: () {},
          ),
        ),
      );
      await _capture(tester, 'before_02_palm_entry');
      await pump(tester, palmLanding(null));
      await _capture(tester, 'before_02b_palm_landing');
    });

    testWidgets('Premium screen as shipped', (tester) async {
      await pump(tester, const PremiumReferenceScreen());
      await _capture(tester, 'before_07a_premium_screen_top');
      await scrollToText(tester, 'Ruh Eşi', alignment: 0.1);
      await _capture(tester, 'before_07b_premium_experiences');
    });

    testWidgets('Fincan Haritası door as shipped', (tester) async {
      await pump(tester, resultTail());
      await _capture(tester, 'before_08_cup_map_door');
    });
  });
}
