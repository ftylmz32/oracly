/// Runtime composition captures for visual comparison against design/reference.
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/constants/app_assets.dart';
import 'package:oracly_new/core/theme/app_theme.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/notifications/memory_notification_port.dart';
import 'package:oracly_new/core/notifications/oracly_notification_providers.dart';
import 'package:oracly_new/features/astrology/presentation/reference/astrology_reference_screen.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_reference_screen.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/coffee/providers/coffee_providers.dart';
import 'package:oracly_new/features/coffee/services/coffee_analysis_port.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture hub runtimes at 390x844', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    final dir = Directory('design/runtime');
    if (!dir.existsSync()) dir.createSync(recursive: true);

    await _shot(
      tester,
      storage,
      'coffee_runtime',
      const CoffeeReferenceScreen(),
    );
    await _shot(
      tester,
      storage,
      'astrology_runtime',
      const AstrologyReferenceScreen(),
    );
    await _shot(
      tester,
      storage,
      'yildizname_runtime',
      const StarMapReferenceScreen(),
    );
  });
}

Future<void> _shot(
  WidgetTester tester,
  LocalStorage storage,
  String name,
  Widget home,
) async {
  const size = Size(390, 844);
  await tester.binding.setSurfaceSize(size);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  final key = GlobalKey();
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        localStorageProvider.overrideWithValue(storage),
        oraclyNotificationPortProvider.overrideWithValue(
          MemoryNotificationPort(),
        ),
        coffeeAnalysisProvider.overrideWithValue(const _OpenAnalysis()),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: RepaintBoundary(key: key, child: home),
      ),
    ),
  );
  await tester.pump();
    await tester.runAsync(() async {
      final context = tester.element(find.byType(MaterialApp));
      await precacheImage(
        const AssetImage(AppAssets.yildiznameHero),
        context,
      );
      await precacheImage(
        const AssetImage(AppAssets.yildiznameArchiveBg),
        context,
      );
      await precacheImage(
        const AssetImage(AppAssets.coffeeRitualHero),
        context,
      );
    });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('design/runtime/$name.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

class _OpenAnalysis implements CoffeeAnalysisPort {
  const _OpenAnalysis();

  @override
  bool get isAvailable => true;

  @override
  Future<CoffeeReading> analyze(CoffeeImagePick image) async {
    throw StateError('unused');
  }
}
