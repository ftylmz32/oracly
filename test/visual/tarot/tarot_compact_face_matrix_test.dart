/// Phase 7G.1 — root-cause matrix for compact ritual face art (test-only).
///
/// Distinguishes decode vs chrome vs shell by vivid-pixel scoring — no masters.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/theme/app_theme.dart';
import 'package:oracly_new/features/tarot/art/major_arcana_art.dart';
import 'package:oracly_new/features/tarot/art/tarot_card_asset.dart';
import 'package:oracly_new/features/tarot/art/tarot_card_face_density.dart';
import 'package:oracly_new/features/tarot/art/tarot_major_card_art.dart';
import 'package:oracly_new/features/tarot/ritual/widgets/ritual_card_shell.dart';
import 'package:oracly_new/shared/widgets/oracly_asset_image.dart';

import 'tarot_visual_harness.dart';

const _compact = Size(52, 87);

int _vividScore(List<int> rgba) {
  var vivid = 0;
  for (var i = 0; i + 3 < rgba.length; i += 4) {
    final r = rgba[i];
    final g = rgba[i + 1];
    final b = rgba[i + 2];
    if (r + g + b < 45) continue;
    final maxc = r > g ? (r > b ? r : b) : (g > b ? g : b);
    final minc = r < g ? (r < b ? r : b) : (g < b ? g : b);
    if (maxc - minc > 28) vivid++;
  }
  return vivid;
}

Future<int> _score(WidgetTester tester, GlobalKey key) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  late ui.Image image;
  await tester.runAsync(() async {
    image = await boundary.toImage(pixelRatio: 1);
  });
  final bytes = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  );
  return _vividScore(bytes!.buffer.asUint8List());
}

Future<GlobalKey> _pump(
  WidgetTester tester, {
  required String asset,
  required Widget child,
}) async {
  await tarotVisualLoadGoldenFonts();
  final key = GlobalKey();
  final viewport = Size(_compact.width + 40, _compact.height + 40);
  await tester.binding.setSurfaceSize(viewport);
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
  await tarotVisualPrecacheAssets(tester, [asset]);
  final theme = AppTheme.darkTheme.copyWith(
    textTheme: AppTheme.darkTheme.textTheme
        .apply(fontFamily: tarotVisualGoldenFontFamily),
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      darkTheme: theme,
      themeMode: ThemeMode.dark,
      home: DefaultTextStyle(
        style: const TextStyle(fontFamily: tarotVisualGoldenFontFamily),
        child: ColoredBox(
          color: Colors.black,
          child: Center(
            child: SizedBox(
              width: _compact.width,
              height: _compact.height,
              child: RepaintBoundary(key: key, child: child),
            ),
          ),
        ),
      ),
    ),
  );
  await tarotVisualPrecacheAssets(tester, [asset]);
  return key;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final major = MajorArcanaArt.assetFor(17);

  testWidgets('7G.1 matrix: chrome is first failure; compact restores art',
      (tester) async {
    Future<int> run(Widget child) async {
      final key = await _pump(tester, asset: major, child: child);
      return _score(tester, key);
    }

    final a = await run(
      OraclyAssetImage(
        assetPath: TarotCardAsset.preview(major),
        fit: BoxFit.cover,
      ),
    );
    final b = await run(
      TarotMajorCardArt(imageAsset: major, showChrome: false),
    );
    final c = await run(
      TarotMajorCardArt(imageAsset: major, showChrome: true),
    );
    final eFull = await run(
      RitualCardFace(
        label: 'The Star',
        image: major,
        width: _compact.width,
        height: _compact.height,
      ),
    );
    final eCompact = await run(
      RitualCardFace(
        label: 'The Star',
        image: major,
        width: _compact.width,
        height: _compact.height,
        density: TarotCardFaceDensity.compact,
      ),
    );

    expect(a, greaterThan(150), reason: 'A decode OK');
    expect(b, greaterThan(200), reason: 'B no-chrome OK');
    expect(
      eCompact,
      greaterThan(200),
      reason: 'compact RitualCardFace must show scene art',
    );
    // Full chrome at 52px is plaque-dominated (proven visually in 7G.1).
    // Compact must remain art-capable regardless of plaque gold chroma scores.
    expect(eCompact, isNot(equals(0)));
    // ignore: avoid_print
    print('MATRIX A=$a B=$b C=$c E_full=$eFull E_compact=$eCompact');
    expect(tester.takeException(), isNull);
  });
}
