/// Phase 7A — deterministic Tarot visual pump/capture (test-only).
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/theme/app_theme.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_footer_actions.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_premium_body.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_premium_scroll.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'tarot_visual_fixtures.dart';

const tarotVisualCanonicalViewport = Size(390, 844);

const tarotVisualViewports = <Size>[
  Size(320, 568),
  Size(390, 844),
  Size(412, 915),
];

const tarotVisualTextScaleViewport = Size(360, 800);
const tarotVisualTextScale = 1.3;

bool get tarotVisualCaptureEnabled =>
    Platform.environment['TAROT_VISUAL_CAPTURE'] == '1';

const tarotVisualRuntimeDir = 'design/runtime/tarot';

Future<LocalStorage> tarotVisualOpenStorage() async {
  SharedPreferences.setMockInitialValues({});
  return LocalStorage.open();
}

Future<void> tarotVisualBindLocale([String code = 'en']) async {
  OraclyL10n.bind(code);
}

Future<void> tarotVisualPumpSettled(
  WidgetTester tester, {
  required Size viewport,
  required Widget child,
  required LocalStorage storage,
  double textScale = 1.0,
  GlobalKey? captureKey,
}) async {
  await tester.binding.setSurfaceSize(viewport);
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final key = captureKey ?? GlobalKey();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [localStorageProvider.overrideWithValue(storage)],
      child: MediaQuery(
        data: MediaQueryData(
          size: viewport,
          textScaler: TextScaler.linear(textScale),
        ),
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: Scaffold(
            body: SafeArea(
              child: RepaintBoundary(key: key, child: child),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

Widget tarotVisualResultTree(
  AiReadingContent content, {
  TarotSpreadType? spread,
}) {
  return ReadingPremiumScrollView(
    padding: const EdgeInsets.only(bottom: 24),
    child: Align(
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReadingPremiumBody(
            content: content,
            spread: spread,
            sectionMaster: 1,
            panelOpacity: 1,
            ambientPhase: 0,
          ),
          ReadingFooterActions(
            progress: 1,
            onNewReading: () {},
            onAskOracle: content.isSafetyResponse ? null : () {},
          ),
        ],
      ),
    ),
  );
}

Future<void> tarotVisualMaybeCapture(
  WidgetTester tester,
  GlobalKey key,
  String name,
) async {
  if (!tarotVisualCaptureEnabled) return;
  final dir = Directory(tarotVisualRuntimeDir);
  if (!dir.existsSync()) dir.createSync(recursive: true);
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$tarotVisualRuntimeDir/$name.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
