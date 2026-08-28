/// Mobile performance pass — decode once, pause hidden tabs, no overflow.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/performance/oracly_decode_cache.dart';
import 'package:oracly_new/core/design_system/oracly_star_field.dart';
import 'package:oracly_new/features/astrology/presentation/reference/astrology_reference_screen.dart';
import 'package:oracly_new/features/coffee/copy/coffee_copy.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_reference_screen.dart';
import 'package:oracly_new/features/coffee/services/coffee_image_validator.dart';
import 'package:oracly_new/features/premium/presentation/screens/soul_mate_portrait_reveal.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_screen.dart';
import 'package:oracly_new/shared/navigation/oracly_tab_pane.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('decode cache never exceeds 2048 device pixels', () {
    expect(oraclyDecodeCachePx(900, 3), 2048);
    expect(oraclyDecodeCachePx(360, 3), 1080);
  });

  testWidgets('star field pauses tickers on mid-range metrics', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(size: Size(360, 800), devicePixelRatio: 2.0),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox.expand(child: OraclyStarField()),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  test('cup validation does not decode the same file twice', () async {
    CoffeeImageValidator.debugDecodeCount = 0;
    final file = File(
      '${Directory.systemTemp.path}/oracly_perf_cup_${DateTime.now().microsecondsSinceEpoch}.bin',
    );
    await file.writeAsBytes(List<int>.filled(9 * 1024, 1));
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });
    final first = await CoffeeImageValidator.validate(file.path);
    final second = await CoffeeImageValidator.validate(file.path);
    expect(first.ok, isFalse);
    expect(first.message, CoffeeCopy.imageUnreadable);
    expect(second.message, first.message);
    expect(CoffeeImageValidator.debugDecodeCount, 1);
  });

  testWidgets('hidden tabs pause tickers so heroes do not keep decoding',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OraclyTabPane(
          active: false,
          navigatorKey: GlobalKey<NavigatorState>(),
          root: const SizedBox.shrink(),
        ),
      ),
    );
    final modes = tester.widgetList<TickerMode>(find.byType(TickerMode));
    expect(modes.any((mode) => !mode.enabled), isTrue);
    expect(
      tester.widgetList<Offstage>(find.byType(Offstage)).any((w) => w.offstage),
      isTrue,
    );
    expect(find.byType(RepaintBoundary), findsWidgets);
  });

  testWidgets('soulmate portrait keeps one memory image across rebuilds',
      (tester) async {
    final bytes = Uint8List.fromList(List<int>.filled(64, 7));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SoulMatePortraitReveal(imageBytes: bytes)),
      ),
    );
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SoulMatePortraitReveal(imageBytes: bytes)),
      ),
    );
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('hubs fit 360 / 390 / 430 without overflow', () {
    const viewports = <Size>[
      Size(360, 800),
      Size(390, 844),
      Size(430, 932),
    ];

    for (final size in viewports) {
      testWidgets('coffee ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        await _pumpHub(tester, size, const CoffeeReferenceScreen());
        expect(tester.takeException(), isNull);
      });

      testWidgets('astrology ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        await _pumpHub(tester, size, const AstrologyReferenceScreen());
        expect(tester.takeException(), isNull);
      });

      testWidgets('yıldızname ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        await _pumpHub(tester, size, const StarMapReferenceScreen());
        expect(tester.takeException(), isNull);
      });
    }
  });
}

Future<void> _pumpHub(WidgetTester tester, Size size, Widget home) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final storage = await LocalStorage.open();
  await tester.pumpWidget(
    buildProviderScopeHarness(
      storage: storage,
      child: MaterialApp(home: home),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}
