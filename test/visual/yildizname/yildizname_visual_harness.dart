/// Phase 7A — deterministic Yıldızname visual pump (test-only).
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

export 'yildizname_visual_fixtures.dart';

const yildiznameVisualCanonicalViewport = Size(390, 844);

const yildiznameVisualViewports = <Size>[
  Size(320, 568),
  Size(390, 844),
  Size(412, 915),
];

const yildiznameVisualTextScaleViewport = Size(360, 800);
const yildiznameVisualTextScale = 1.3;

const yildiznameVisualGoldenFontFamily = 'YildiznameGoldenRoboto';

bool _fontsLoaded = false;

Future<void> yildiznameVisualLoadGoldenFonts() async {
  if (_fontsLoaded) return;
  final regular = File('test/fonts/Roboto-Regular.ttf');
  final medium = File('test/fonts/Roboto-Medium.ttf');
  if (!regular.existsSync() || !medium.existsSync()) {
    throw StateError('Missing test/fonts/Roboto-*.ttf for Yıldızname goldens.');
  }
  final loader = FontLoader(yildiznameVisualGoldenFontFamily)
    ..addFont(Future.value(ByteData.view(regular.readAsBytesSync().buffer)))
    ..addFont(Future.value(ByteData.view(medium.readAsBytesSync().buffer)));
  await loader.load();
  _fontsLoaded = true;
}

ThemeData _goldenTheme() {
  final base = AppTheme.darkTheme;
  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: yildiznameVisualGoldenFontFamily),
    primaryTextTheme:
        base.primaryTextTheme.apply(fontFamily: yildiznameVisualGoldenFontFamily),
  );
}

bool get yildiznameVisualCaptureEnabled =>
    Platform.environment['YILDIZNAME_VISUAL_CAPTURE'] == '1';

const yildiznameVisualRuntimeDir = 'design/runtime/yildizname';

Future<LocalStorage> yildiznameVisualOpenStorage() async {
  SharedPreferences.setMockInitialValues({});
  return LocalStorage.open();
}

Future<void> yildiznameVisualBindLocale([String code = 'tr']) async {
  OraclyL10n.bind(code);
}

Future<void> yildiznameVisualPumpSettled(
  WidgetTester tester, {
  required Size viewport,
  required Widget child,
  required LocalStorage storage,
  double textScale = 1.0,
  GlobalKey? captureKey,
  List<Override>? overrides,
}) async {
  await yildiznameVisualLoadGoldenFonts();
  await tester.binding.setSurfaceSize(viewport);
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final key = captureKey ?? GlobalKey();
  final theme = _goldenTheme();
  await tester.pumpWidget(
    buildProviderScopeHarness(
      storage: storage,
      overrides: overrides ?? const [],
      child: MediaQuery(
        data: MediaQueryData(
          size: viewport,
          textScaler: TextScaler.linear(textScale),
        ),
        child: MaterialApp(
          theme: theme,
          darkTheme: theme,
          themeMode: ThemeMode.dark,
          home: DefaultTextStyle(
            style: const TextStyle(fontFamily: yildiznameVisualGoldenFontFamily),
            child: RepaintBoundary(key: key, child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> yildiznameVisualMaybeCapture(
  WidgetTester tester,
  GlobalKey key,
  String name,
) async {
  if (!yildiznameVisualCaptureEnabled) return;
  final dir = Directory(yildiznameVisualRuntimeDir);
  if (!dir.existsSync()) dir.createSync(recursive: true);
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$yildiznameVisualRuntimeDir/$name.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
