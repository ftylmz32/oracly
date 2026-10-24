/// Premium paywall at 320/360/390/430 px and text scale 1.0/1.3/1.5 with a
/// store that returned all three Android plans: no overflow or exception at
/// the top or after scrolling to the legal footer, and every section that
/// sells (hero, three benefits, store prices, CTA, billing disclosure) is
/// laid out. Set PREMIUM_VISUAL_CAPTURE_DIR to also write PNG screenshots.
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/theme/app_theme.dart';
import 'package:oracly_new/features/premium/models/premium_models.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_result.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_legal_disclosure.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_reference_hero_card.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_reference_plan_card.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_reference_screen.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_reference_value_highlights.dart';
import 'package:oracly_new/features/premium/services/premium_purchase_port.dart';
import 'package:oracly_new/shared/widgets/oracly_gold_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

/// Android store that returned monthly, yearly and lifetime with prices.
class _PricedStore implements PremiumPurchasePort {
  @override
  bool get isConfigured => true;
  @override
  bool get canAttemptRestore => true;
  @override
  Future<void> prepare() async {}
  @override
  String? priceLabel(PremiumPlanKind plan) => 'STORE-${plan.name}';
  @override
  Future<PremiumPurchaseResult> purchase(PremiumPlanKind plan) async =>
      PremiumPurchaseResult.cancelled();
  @override
  Future<PremiumPurchaseResult> restore() async =>
      PremiumPurchaseResult.noneFound();
  @override
  Future<PremiumPurchaseResult?> consumeUnsolicitedGrant() async => null;
}

const _viewports = <Size>[
  Size(320, 640),
  Size(360, 800),
  Size(390, 844),
  Size(430, 932),
];
const _scales = <double>[1.0, 1.3, 1.5];

final _captureDir = Platform.environment['PREMIUM_VISUAL_CAPTURE_DIR'];
final _boundary = GlobalKey();

Future<void> _loadFonts() async {
  final sdk = File(Platform.resolvedExecutable).parent.parent.parent.parent;
  final material = '${sdk.path}/artifacts/material_fonts';
  Future<ByteData> read(String path) async =>
      ByteData.view(File(path).readAsBytesSync().buffer);
  final roboto = FontLoader('Roboto');
  for (final f in ['roboto-regular', 'roboto-medium', 'roboto-bold']) {
    final path = '$material/$f.ttf';
    if (File(path).existsSync()) roboto.addFont(read(path));
  }
  roboto.addFont(read('test/fonts/Roboto-Regular.ttf'));
  await roboto.load();
  final iconsPath = '$material/materialicons-regular.otf';
  if (File(iconsPath).existsSync()) {
    await (FontLoader('MaterialIcons')..addFont(read(iconsPath))).load();
  }
}

ThemeData _darkRoboto() {
  final base = AppTheme.dark;
  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: 'Roboto'),
    primaryTextTheme: base.primaryTextTheme.apply(fontFamily: 'Roboto'),
  );
}

Future<void> _capture(WidgetTester tester, String name) async {
  final dir = _captureDir;
  if (dir == null || dir.isEmpty) return;
  await tester.runAsync(() async {
    final boundary = _boundary.currentContext!.findRenderObject()!
        as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory(dir).createSync(recursive: true);
    File('$dir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Future<void> _pump(WidgetTester tester, Size size, double scale) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final storage = await LocalStorage.open();
  await tester.pumpWidget(
    RepaintBoundary(
      key: _boundary,
      child: buildProviderScopeHarness(
        storage: storage,
        purchasePort: _PricedStore(),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          // Production always runs the dark theme (light is not selectable).
          theme: _darkRoboto(),
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(scale),
              padding: const EdgeInsets.only(top: 24, bottom: 24),
              disableAnimations: true,
            ),
            child: const PremiumReferenceScreen(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 80));
  // Let asset images decode so screenshots show the cinematic art.
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 250)),
  );
  await tester.pump(const Duration(milliseconds: 80));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_loadFonts);

  for (final size in _viewports) {
    for (final scale in _scales) {
      final label = '${size.width.toInt()}x${size.height.toInt()}@${scale}x';
      testWidgets('premium paywall $label', (tester) async {
        await _pump(tester, size, scale);

        expect(tester.takeException(), isNull);
        expect(find.byType(PremiumReferenceHeroCard), findsOneWidget);
        expect(find.text(PremiumCopy.heroTitle), findsWidgets);
        expect(find.byType(PremiumReferenceValueHighlights), findsOneWidget);
        final benefits = PremiumCatalogue.concretePremiumExperiences;
        expect(benefits, hasLength(3));
        for (final benefit in benefits) {
          expect(
            find.text(benefit.title, skipOffstage: false),
            findsWidgets,
          );
        }
        expect(
          find.text(PremiumCopy.benefitCoffeeTitle, skipOffstage: false),
          findsNothing,
          reason: 'coffee is free; never sold as a Premium benefit',
        );
        await _capture(tester, '${label}_top');

        await tester.ensureVisible(
          find.byType(PremiumReferenceValueHighlights),
        );
        await tester.pump(const Duration(milliseconds: 80));
        expect(tester.takeException(), isNull);
        await _capture(tester, '${label}_benefits');

        final scrollable = find.byType(Scrollable).first;
        await tester.scrollUntilVisible(
          find.byType(PremiumLegalDisclosure, skipOffstage: false),
          400,
          scrollable: scrollable,
        );
        await tester.pump(const Duration(milliseconds: 80));
        expect(tester.takeException(), isNull);
        for (final kind in PremiumPlanKind.values) {
          expect(
            find.textContaining('STORE-${kind.name}', skipOffstage: false),
            findsWidgets,
            reason: 'store-returned ${kind.name} price is shown verbatim',
          );
        }
        expect(find.byType(OraclyGoldButton, skipOffstage: false),
            findsOneWidget);
        // Frame the plan cards from the first one down to the CTA.
        final firstPlan = find.textContaining('STORE-monthly');
        await tester.ensureVisible(firstPlan);
        await Scrollable.ensureVisible(
          tester.element(firstPlan),
          alignment: 0.15,
        );
        await tester.pump(const Duration(milliseconds: 80));
        expect(tester.takeException(), isNull);
        final cards = find.byType(PremiumReferencePlanCard);
        expect(cards, findsNWidgets(PremiumPlanKind.values.length));
        for (final paragraph in tester.renderObjectList<RenderParagraph>(
          find.descendant(of: cards, matching: find.byType(RichText)),
        )) {
          expect(paragraph.didExceedMaxLines, isFalse,
              reason: 'plan name, renewal terms and price are never cut off: '
                  '"${paragraph.text.toPlainText()}"');
        }
        await _capture(tester, '${label}_plans');
        await tester.ensureVisible(find.byType(PremiumLegalDisclosure));
        await tester.pump(const Duration(milliseconds: 80));
        expect(find.byType(PremiumLegalDisclosure), findsOneWidget);
        expect(find.textContaining('₺', skipOffstage: false), findsNothing,
            reason: 'no price is invented outside the store label');
        await _capture(tester, '${label}_bottom');
      });
    }
  }
}
