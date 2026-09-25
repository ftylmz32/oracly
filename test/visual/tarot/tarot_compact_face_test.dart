/// Phase 7G.1 — compact settled face art presence (production widgets).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/theme/app_theme.dart';
import 'package:oracly_new/features/tarot/art/major_arcana_art.dart';
import 'package:oracly_new/features/tarot/art/tarot_card_face_density.dart';
import 'package:oracly_new/features/tarot/ritual/widgets/ritual_card_shell.dart';

import 'tarot_golden_harness.dart';
import 'tarot_visual_harness.dart';

const _compact = Size(52, 87);

Future<GlobalKey> _pumpCompact(
  WidgetTester tester, {
  required String asset,
  required Widget child,
  double dpr = 1.0,
  Size size = _compact,
}) async {
  await tarotVisualLoadGoldenFonts();
  final key = GlobalKey();
  final viewport = Size(size.width + 48, size.height + 48);
  await tester.binding.setSurfaceSize(viewport);
  tester.view.physicalSize = Size(viewport.width * dpr, viewport.height * dpr);
  tester.view.devicePixelRatio = dpr;
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
              width: size.width,
              height: size.height,
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
  final minor = 'lib/assets/images/tarot/minor_arcana/cups/01_ace_cups.webp';

  testWidgets('compact Major upright DPR1 shows art', (tester) async {
    final key = await _pumpCompact(
      tester,
      asset: major,
      child: RitualCardFace(
        label: 'The Star',
        image: major,
        width: _compact.width,
        height: _compact.height,
        density: TarotCardFaceDensity.compact,
      ),
    );
    await tarotGoldenExpect(tester, key, 'compact_major_upright_52');
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact Major reversed DPR1 shows art', (tester) async {
    final key = await _pumpCompact(
      tester,
      asset: major,
      child: RitualCardFace(
        label: 'The Star',
        image: major,
        width: _compact.width,
        height: _compact.height,
        reversed: true,
        density: TarotCardFaceDensity.compact,
      ),
    );
    await tarotGoldenExpect(tester, key, 'compact_major_reversed_52');
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact Minor upright DPR1 shows art', (tester) async {
    final key = await _pumpCompact(
      tester,
      asset: minor,
      child: RitualCardFace(
        label: 'Ace of Cups',
        image: minor,
        width: _compact.width,
        height: _compact.height,
        density: TarotCardFaceDensity.compact,
      ),
    );
    await tarotGoldenExpect(tester, key, 'compact_minor_upright_52');
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact Major DPR2 shows art', (tester) async {
    final key = await _pumpCompact(
      tester,
      asset: major,
      dpr: 2.0,
      child: RitualCardFace(
        label: 'The Star',
        image: major,
        width: _compact.width,
        height: _compact.height,
        density: TarotCardFaceDensity.compact,
      ),
    );
    await tarotGoldenExpect(tester, key, 'compact_major_upright_52_dpr2');
    expect(tester.takeException(), isNull);
  });

  testWidgets('full RitualCardFace 132x222 unchanged chrome path', (tester) async {
    final key = await _pumpCompact(
      tester,
      asset: major,
      size: const Size(132, 222),
      child: RitualCardFace(
        label: 'The Star',
        image: major,
        width: 132,
        height: 222,
      ),
    );
    await tarotGoldenExpect(tester, key, 'firewall_ritual_face_132');
    expect(tester.takeException(), isNull);
  });

  testWidgets('full RitualCardFace 90x150 control', (tester) async {
    final key = await _pumpCompact(
      tester,
      asset: major,
      size: const Size(90, 150),
      child: RitualCardFace(
        label: 'The Star',
        image: major,
        width: 90,
        height: 150,
      ),
    );
    await tarotGoldenExpect(tester, key, 'firewall_ritual_face_90');
    expect(tester.takeException(), isNull);
  });
}
