/// Final visual art direction — mix, chrome, glow, radii, breakpoints.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/design_system/app_borders.dart';
import 'package:oracly_new/core/design_system/app_colors.dart';
import 'package:oracly_new/core/design_system/app_glows.dart';
import 'package:oracly_new/core/design_system/app_layout.dart';
import 'package:oracly_new/core/design_system/cinematic_lighting/cinematic_lighting_tokens.dart';
import 'package:oracly_new/core/design_system/oracly_app_bar.dart';
import 'package:oracly_new/core/design_system/oracly_art_direction.dart';
import 'package:oracly_new/core/design_system/oracly_chrome.dart';
import 'package:oracly_new/core/design_system/oracly_crystal_capsule.dart';
import 'package:oracly_new/core/design_system/oracly_header_action.dart';
import 'package:oracly_new/features/home/widgets/home_premium_gem_counter.dart';
import 'package:oracly_new/features/home/widgets/home_status_header.dart';

void main() {
  test('70/20/10 mix uses calm navy violet and antique gold', () {
    expect(OraclyArtDirection.calm, AppColors.nearBlack);
    expect(OraclyArtDirection.navy, AppColors.midnightNavy);
    expect(OraclyArtDirection.violet, AppColors.primaryPurple);
    expect(OraclyArtDirection.gold, AppColors.gold);
    expect(OraclyArtDirection.ivory, AppColors.ivory);
    expect(OraclyArtDirection.amber, AppColors.amber);
    expect(OraclyArtDirection.goldFillMax, 0.11);
  });

  test('glow and gold borders stay within the highlight cap', () {
    expect(OraclyArtDirection.clampGoldGlow(0.80), 0.24);
    expect(OraclyArtDirection.clampVioletGlow(0.80), 0.18);
    expect(OraclyArtDirection.clampAmberGlow(0.80), 0.14);
    expect(OraclyChrome.borderSelected, lessThanOrEqualTo(0.54));
    expect(OraclyChrome.glowStrong, OraclyArtDirection.goldGlowMax);
  });

  test('hero glow source is gold and violet only — no neon pink', () {
    final source = File('lib/core/design_system/app_glows.dart').readAsStringSync();
    expect(source, isNot(contains('accentPink')));
    for (final shadow in AppGlows.hero()) {
      expect(shadow.color.a, lessThanOrEqualTo(OraclyArtDirection.goldGlowMax));
    }
  });

  test('radii stay on the approved 16·20·24·28·32 ladder', () {
    expect(OraclyArtDirection.radii, [16, 20, 24, 28, 32]);
    expect(AppBorders.cardRadius, OraclyChrome.cardRadius);
    expect(AppBorders.heroRadius, OraclyChrome.heroRadius);
    expect(AppBorders.buttonRadius, OraclyChrome.pillRadius);
  });

  test('responsive canvases match the art-direction phone set', () {
    expect(
      OraclyArtDirection.phoneWidths,
      [360, 375, 390, 411, 430, 600],
    );
    expect(AppLayout.phoneWidths, OraclyArtDirection.phoneWidths);
  });

  test('home nebula is navy/violet, never accent pink', () {
    expect(
      CinematicLightingTokens.nebulaSecondary(CinematicLightingPreset.home),
      isNot(AppColors.accentPink),
    );
    expect(
      CinematicLightingTokens.nebulaSecondary(CinematicLightingPreset.neutral),
      isNot(AppColors.accentPink),
    );
  });

  test('chamber atmospheres stay distinct — not a flattened wash', () {
    final coffee = File(
      'lib/features/coffee/presentation/reference/coffee_reference_atmosphere.dart',
    ).readAsStringSync();
    final palm = File(
      'lib/features/palm/presentation/palm_atmosphere.dart',
    ).readAsStringSync();
    final astrology = File(
      'lib/features/astrology/presentation/reference/astrology_reference_atmosphere.dart',
    ).readAsStringSync();
    final star = File(
      'lib/features/star_map/presentation/reference/star_map_reference_atmosphere.dart',
    ).readAsStringSync();
    final orPalettes = File(
      'lib/features/companion/presentation/reference/companion_or_atmosphere_palettes.dart',
    ).readAsStringSync();
    final profile = File(
      'lib/screens/profile/reference/profile_reference_atmosphere.dart',
    ).readAsStringSync();
    final premium = File(
      'lib/features/premium/presentation/reference/premium_reference_atmosphere.dart',
    ).readAsStringSync();

    expect(coffee, contains('amberGlow'));
    expect(
      File(
        'lib/features/coffee/presentation/reference/coffee_reference_tokens.dart',
      ).readAsStringSync(),
      contains('0xFFC47A2A'),
    );
    expect(palm, contains('Intimate'));
    expect(astrology, contains('astrologyObservatoryBg'));
    expect(astrology, contains('AstrologyStarfield'));
    expect(star, contains('StarMapArchiveHaze'));
    expect(orPalettes, contains('OrModePalette'));
    expect(profile, contains('profileJournalHero'));
    expect(premium, contains('premiumChamberHero'));
    expect(premium, contains('0xFFDCC9A3'));
  });

  testWidgets('gem counter is the canonical crystal capsule', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HomePremiumGemCounter(count: '12')),
      ),
    );
    expect(find.byType(OraclyCrystalCapsule), findsOneWidget);
  });

  testWidgets('home chrome uses the canonical header action', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HomeStatusHeader())),
    );
    expect(find.byType(OraclyHeaderAction), findsNWidgets(2));
  });

  for (final width in OraclyArtDirection.phoneWidths) {
    testWidgets('app bar does not overflow at $width', (tester) async {
      final size = Size(width, 800);
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: size),
          child: const MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: OraclyAppBar(
                  title: 'AYARLAR',
                  trailing: OraclyCrystalCapsule(count: '9999'),
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(OraclyHeaderAction), findsOneWidget);
      expect(find.byType(OraclyCrystalCapsule), findsOneWidget);
    });
  }
}
