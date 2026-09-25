/// Phase 7A — deterministic Tarot visual pump/capture (test-only).
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/theme/app_theme.dart';
import 'package:oracly_new/features/tarot/art/major_arcana_art.dart';
import 'package:oracly_new/features/tarot/art/tarot_card_asset.dart';
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

/// Deterministic golden font — avoids Ahem plaque inflation on small faces.
const tarotVisualGoldenFontFamily = 'TarotGoldenRoboto';

bool _tarotVisualFontsLoaded = false;

Future<void> tarotVisualLoadGoldenFonts() async {
  if (_tarotVisualFontsLoaded) return;
  final regular = File('test/fonts/Roboto-Regular.ttf');
  final medium = File('test/fonts/Roboto-Medium.ttf');
  if (!regular.existsSync() || !medium.existsSync()) {
    throw StateError(
      'Missing test/fonts/Roboto-*.ttf required for Tarot golden determinism.',
    );
  }
  final loader = FontLoader(tarotVisualGoldenFontFamily)
    ..addFont(
      Future.value(ByteData.view(regular.readAsBytesSync().buffer)),
    )
    ..addFont(
      Future.value(ByteData.view(medium.readAsBytesSync().buffer)),
    );
  await loader.load();
  _tarotVisualFontsLoaded = true;
}

ThemeData _tarotVisualGoldenTheme() {
  final base = AppTheme.darkTheme;
  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: tarotVisualGoldenFontFamily),
    primaryTextTheme:
        base.primaryTextTheme.apply(fontFamily: tarotVisualGoldenFontFamily),
  );
}

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

/// Decode local Tarot faces before golden capture (no network).
Future<void> tarotVisualPrecacheAssets(
  WidgetTester tester,
  Iterable<String> faceAssets,
) async {
  await tester.runAsync(() async {
    final context = tester.element(find.byType(MaterialApp));
    Future<void> one(String path) async {
      if (path.isEmpty) return;
      await precacheImage(AssetImage(path), context);
    }

    await one(MajorArcanaArt.cardBack);
    await one(TarotCardAsset.preview(MajorArcanaArt.cardBack));
    await one(TarotCardAsset.full(MajorArcanaArt.cardBack));
    for (final raw in faceAssets) {
      await one(raw);
      await one(TarotCardAsset.preview(raw));
      await one(TarotCardAsset.full(raw));
    }
    // Allow Image.asset cacheWidth re-decodes to finish (golden settle).
    await Future<void>.delayed(const Duration(milliseconds: 500));
  });
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<void> tarotVisualPumpSettled(
  WidgetTester tester, {
  required Size viewport,
  required Widget child,
  required LocalStorage storage,
  double textScale = 1.0,
  GlobalKey? captureKey,
  bool wrapSafeArea = true,
  Iterable<String> precacheFaces = const [],
}) async {
  await tarotVisualLoadGoldenFonts();
  await tester.binding.setSurfaceSize(viewport);
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() => tester.binding.setSurfaceSize(null));

  // Warm the image cache BEFORE first paint so OraclyAssetImage never sticks
  // on errorBuilder from a raced first decode (ritual faces).
  if (precacheFaces.isNotEmpty) {
    await tester.pumpWidget(
      const MaterialApp(home: SizedBox.shrink()),
    );
    await tarotVisualPrecacheAssets(tester, precacheFaces);
  }

  final key = captureKey ?? GlobalKey();
  final body = RepaintBoundary(key: key, child: child);
  final theme = _tarotVisualGoldenTheme();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [localStorageProvider.overrideWithValue(storage)],
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
            style: const TextStyle(fontFamily: tarotVisualGoldenFontFamily),
            child: Scaffold(
              body: wrapSafeArea ? SafeArea(child: body) : body,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
  if (precacheFaces.isNotEmpty) {
    await tarotVisualPrecacheAssets(tester, precacheFaces);
  }
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
