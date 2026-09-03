/// OR-V2 — dedicated Luna route, chrome removal, gold icons, hierarchy.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/design_system/app_icons.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/navigation/oracly_navigation_service.dart';
import 'package:oracly_new/core/navigation/oracly_routes.dart';
import 'package:oracly_new/core/theme/app_theme.dart';
import 'package:oracly_new/features/ai/production/oracly_ai_providers.dart';
import 'package:oracly_new/features/ai/production/unconfigured_oracly_ai_service.dart';
import 'package:oracly_new/features/companion/copy/companion_copy.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_feature_shortcuts.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_gold_line_icon.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_output_mode.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_screen.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/shared/widgets/oracly_bottom_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> boot() async {
    SharedPreferences.setMockInitialValues({GemWalletStore.balanceKey: 1250});
    final storage = await LocalStorage.open();
    return ProviderContainer(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
        oraclyAiServiceProvider.overrideWithValue(
          const UnconfiguredOraclyAiService(allowsLocalFallback: true),
        ),
      ],
    );
  }

  testWidgets('OR-V2 gold line icons render for all five shortcuts', (tester) async {
    OraclyL10n.bind('tr');
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CompanionFeatureShortcuts())),
    );
    await tester.pump();
    expect(find.byType(CompanionGoldLineIcon), findsNWidgets(5));
    expect(find.byIcon(Icons.style_outlined), findsNothing);
    expect(find.byIcon(Icons.coffee_outlined), findsNothing);
    expect(find.byIcon(Icons.favorite_border), findsNothing);
  });

  testWidgets('OR-V2 dedicated /chat has no bottom nav or output-mode strip',
      (tester) async {
    OraclyL10n.bind('tr');
    final container = await boot();
    addTearDown(container.dispose);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark,
          routes: {
            '/': (_) => const Scaffold(body: Center(child: Text('home-stub'))),
            OraclyRoutes.chat: (_) => const CompanionReferenceScreen(),
          },
        ),
      ),
    );
    await tester.pump();
    final ctx = tester.element(find.text('home-stub'));
    OraclyNavigationService.openChat(ctx);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();
    expect(find.byType(CompanionReferenceScreen), findsOneWidget);
    expect(find.byType(OraclyBottomBar), findsNothing);
    expect(find.byType(CompanionReferenceOutputMode), findsNothing);
    expect(find.byIcon(AppIcons.back), findsWidgets);
  });

  testWidgets('OR-V2 back pops dedicated chat to previous route', (tester) async {
    OraclyL10n.bind('tr');
    final container = await boot();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark,
          routes: {
            '/': (_) => Scaffold(
                  body: Builder(
                    builder: (context) => TextButton(
                      onPressed: () =>
                          OraclyNavigationService.openChat(context),
                      child: const Text('open-or'),
                    ),
                  ),
                ),
            OraclyRoutes.chat: (_) => const CompanionReferenceScreen(),
          },
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('open-or'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(CompanionReferenceScreen), findsOneWidget);
    await tester.tap(find.byIcon(AppIcons.back).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('open-or'), findsOneWidget);
    expect(find.byType(CompanionReferenceScreen), findsNothing);
  });

  testWidgets('OR-V2 system back pops dedicated chat', (tester) async {
    OraclyL10n.bind('tr');
    final container = await boot();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark,
          routes: {
            '/': (_) => Scaffold(
                  body: Builder(
                    builder: (context) => TextButton(
                      onPressed: () =>
                          OraclyNavigationService.openChat(context),
                      child: const Text('open-or'),
                    ),
                  ),
                ),
            OraclyRoutes.chat: (_) => const CompanionReferenceScreen(),
          },
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('open-or'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    expect(nav.canPop(), isTrue);
    nav.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('open-or'), findsOneWidget);
  });

  for (final lang in ['tr', 'en', 'ru']) {
    testWidgets('OR-V2 idle copy binds $lang', (tester) async {
      OraclyL10n.bind(lang);
      final container = await boot();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const CompanionReferenceScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(CompanionCopy.screenTitle), findsWidgets);
      expect(find.byType(OraclyBottomBar), findsNothing);
      // Shortcuts sit in the idle scroll pane — ensure at least the chrome is live.
      expect(find.byType(CompanionReferenceScreen), findsOneWidget);
    });
  }

  for (final size in const [
    Size(320, 568),
    Size(390, 844),
    Size(412, 915),
    Size(426, 927),
  ]) {
    testWidgets(
        'OR-V2 renders ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
      OraclyL10n.bind('tr');
      final container = await boot();
      addTearDown(container.dispose);
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.dark,
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: size.width < 360
                    ? const TextScaler.linear(1.2)
                    : TextScaler.noScaling,
                disableAnimations: true,
              ),
              child: const CompanionReferenceScreen(),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(OraclyBottomBar), findsNothing);
      expect(find.byType(CompanionReferenceOutputMode), findsNothing);
    });
  }
}
