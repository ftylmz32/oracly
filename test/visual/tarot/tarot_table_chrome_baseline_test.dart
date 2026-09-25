/// Phase 7B — live table structural baselines at target viewports.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/theme/app_theme.dart';
import 'package:oracly_new/features/tarot/controllers/tarot_flow_controller.dart';
import 'package:oracly_new/features/tarot/controllers/tarot_reading_controller.dart';
import 'package:oracly_new/features/tarot/data/repositories/tarot_reading_repository_impl.dart';
import 'package:oracly_new/features/tarot/presentation/screens/tarot_home_screen.dart';
import 'package:oracly_new/features/tarot/ritual/table/tarot_table_background.dart';
import 'package:oracly_new/features/tarot/ritual/table/tarot_table_intent_overlay.dart';
import 'package:oracly_new/features/tarot/ritual/table/tarot_table_scene.dart';
import 'package:oracly_new/features/tarot/shared/tarot_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tarot_visual_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => OraclyL10n.bind('en'));

  Future<void> pumpTable(WidgetTester tester, Size viewport) async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final reading = TarotReadingController(
      repository: TarotReadingRepositoryImpl.fromStorage(storage),
    );
    addTearDown(reading.dispose);
    final flow = TarotFlowController();
    addTearDown(flow.dispose);

    await tester.binding.setSurfaceSize(viewport);
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageProvider.overrideWithValue(storage)],
        child: TarotScope(
          flow: flow,
          reading: reading,
          child: MediaQuery(
            data: MediaQueryData(size: viewport),
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: ThemeMode.dark,
              home: const TarotHomeScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
  }

  for (final size in tarotVisualViewports) {
    testWidgets(
      'table intention settled @ ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        await pumpTable(tester, size);
        expect(find.byType(TarotHomeScreen), findsOneWidget);
        expect(find.byType(TarotTableScene), findsOneWidget);
        expect(find.byType(TarotTableBackground), findsOneWidget);
        expect(find.byType(TarotTableIntentOverlay), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('table @ 360x800 textScale 1.3 no exception', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final reading = TarotReadingController(
      repository: TarotReadingRepositoryImpl.fromStorage(storage),
    );
    addTearDown(reading.dispose);
    final flow = TarotFlowController();
    addTearDown(flow.dispose);

    final viewport = tarotVisualTextScaleViewport;
    await tester.binding.setSurfaceSize(viewport);
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageProvider.overrideWithValue(storage)],
        child: TarotScope(
          flow: flow,
          reading: reading,
          child: MediaQuery(
            data: MediaQueryData(
              size: viewport,
              textScaler: const TextScaler.linear(tarotVisualTextScale),
            ),
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: const TarotTableScene(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(TarotTableScene), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
