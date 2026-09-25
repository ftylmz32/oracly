/// Phase 7G — golden compare + settled surface composers (test-only).
library;

import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/theme/app_colors.dart';
import 'package:oracly_new/core/theme/app_spacing.dart';
import 'package:oracly_new/core/theme/app_text_styles.dart';
import 'package:oracly_new/core/theme/app_theme.dart';
import 'package:oracly_new/features/tarot/controllers/tarot_flow_controller.dart';
import 'package:oracly_new/features/tarot/controllers/tarot_reading_controller.dart';
import 'package:oracly_new/features/tarot/data/repositories/tarot_reading_repository_impl.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/presentation/screens/tarot_home_screen.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/card_reveal_spread.dart';
import 'package:oracly_new/features/tarot/ritual/deck_visual_state.dart';
import 'package:oracly_new/features/tarot/ritual/table/card_flight_actor.dart';
import 'package:oracly_new/features/tarot/ritual/table/tarot_table_background.dart';
import 'package:oracly_new/features/tarot/ritual/table/tarot_table_deck_stage.dart';
import 'package:oracly_new/features/tarot/ritual/table/tarot_table_hint.dart';
import 'package:oracly_new/features/tarot/ritual/table/tarot_table_intent_overlay.dart';
import 'package:oracly_new/features/tarot/ritual/table/tarot_table_phase.dart';
import 'package:oracly_new/features/tarot/ritual/table/tarot_table_spread_overlay.dart';
import 'package:oracly_new/features/tarot/ritual/tarot_ritual_controller.dart';
import 'package:oracly_new/features/tarot/ritual/tarot_ritual_stage.dart';
import 'package:oracly_new/features/tarot/ritual/widgets/ritual_spread_slots.dart';
import 'package:oracly_new/features/tarot/shared/tarot_scope.dart';
import 'package:oracly_new/features/tarot/theme/tarot_tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tarot_visual_harness.dart';

/// Relative to `test/visual/tarot/` → `test/goldens/tarot/<name>.png`.
String tarotGoldenPath(String name) => '../../goldens/tarot/$name.png';

const tarotGoldenMasterDir = 'test/goldens/tarot';

Future<void> tarotGoldenExpect(
  WidgetTester tester,
  GlobalKey key,
  String name, {
  Iterable<String> precacheFaces = const [],
}) async {
  if (precacheFaces.isNotEmpty) {
    await tarotVisualPrecacheAssets(tester, precacheFaces);
  }
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await expectLater(
    find.byKey(key),
    matchesGoldenFile(tarotGoldenPath(name)),
  );
}

Future<(LocalStorage, TarotFlowController, TarotReadingController)>
    tarotGoldenOpenTableScope() async {
  SharedPreferences.setMockInitialValues({});
  final storage = LocalStorage(await SharedPreferences.getInstance());
  final reading = TarotReadingController(
    repository: TarotReadingRepositoryImpl.fromStorage(storage),
  );
  final flow = TarotFlowController();
  return (storage, flow, reading);
}

/// Full live table at intention (production [TarotHomeScreen]).
Future<GlobalKey> tarotGoldenPumpIntention(
  WidgetTester tester, {
  Size viewport = tarotVisualCanonicalViewport,
  double textScale = 1.0,
}) async {
  await tarotVisualLoadGoldenFonts();
  final (storage, flow, reading) = await tarotGoldenOpenTableScope();
  addTearDown(reading.dispose);
  addTearDown(flow.dispose);
  final key = GlobalKey();
  await tester.binding.setSurfaceSize(viewport);
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final theme = AppTheme.darkTheme.copyWith(
    textTheme: AppTheme.darkTheme.textTheme
        .apply(fontFamily: tarotVisualGoldenFontFamily),
    primaryTextTheme: AppTheme.darkTheme.primaryTextTheme
        .apply(fontFamily: tarotVisualGoldenFontFamily),
  );
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
            child: RepaintBoundary(
              key: key,
              child: TarotScope(
                flow: flow,
                reading: reading,
                child: const TarotHomeScreen(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
  await tarotVisualPrecacheAssets(tester, const []);
  return key;
}

/// Production overlays on the real table background — spread picker only.
Widget tarotGoldenSpreadPickerSurface() {
  return Stack(
    fit: StackFit.expand,
    children: [
      const TarotTableBackground(),
      SafeArea(
        child: Column(
          children: [
            const SizedBox(height: TarotTokens.tableTitleTopGap),
            Text(
              'Tarot',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.gold.withValues(alpha: 0.9),
                letterSpacing: TarotTokens.tableTitleTracking,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TarotTableIntentOverlay(
              selectedId: 'love',
              receded: true,
              onSelected: (_) {},
            ),
            const SizedBox(height: AppSpacing.md),
            TarotTableSpreadOverlay(
              selected: null,
              onSelected: (_) {},
            ),
            const Spacer(),
          ],
        ),
      ),
    ],
  );
}

/// Draw-ready / partial ritual composition from production table children.
Widget tarotGoldenRitualSurface({
  required TarotSpreadType spread,
  required List<RevealCardData> placed,
  required TarotTablePhase phase,
  bool showHint = true,
  bool showFlight = true,
}) {
  final ritual = TarotRitualController()
    ..setVisual(
      const DeckVisualState(
        stage: TarotRitualStage.draw,
        stackDepth: 1,
        shuffleProgress: 1,
      ),
    );
  for (final c in placed) {
    ritual.placed.add(c);
  }
  final flightKey = GlobalKey<CardFlightActorState>();
  return Stack(
    fit: StackFit.expand,
    children: [
      const TarotTableBackground(),
      SafeArea(
        child: Column(
          children: [
            const SizedBox(height: TarotTokens.tableTitleTopGap),
            Text(
              'Tarot',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.gold.withValues(alpha: 0.9),
                letterSpacing: TarotTokens.tableTitleTracking,
              ),
            ),
            if (spread.cardCount > 1) ...[
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: RitualSpreadSlots(placed: placed, spread: spread),
              ),
            ],
            Expanded(
              child: TarotTableDeckStage(
                ritual: ritual,
                phase: phase,
                flightKey: flightKey,
                showFlight: showFlight,
                reducedMotion: true,
                placeTarget: null,
                onInteracted: () {},
                onRequestDraw: () async => null,
                onFlightComplete: (_) async {},
              ),
            ),
            if (showHint && phase == TarotTablePhase.draw)
              const Padding(
                padding: EdgeInsets.only(
                  bottom: TarotTokens.tableHintBottomInset,
                ),
                child: TarotTableHint(visible: true),
              ),
          ],
        ),
      ),
    ],
  );
}

String tarotGoldenSha256(String relativePath) {
  final bytes = File(relativePath).readAsBytesSync();
  return sha256.convert(bytes).toString();
}
