import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/copy/conversation_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/theme/app_theme.dart';
import 'package:oracly_new/features/ai/production/oracly_ai_providers.dart';
import 'package:oracly_new/features/ai/production/unconfigured_oracly_ai_service.dart';
import 'package:oracly_new/features/companion/copy/companion_copy.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_app_bar.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_idle.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_identity.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_input_bar.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_plus_slot.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_screen.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_voice_slot.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const viewports = <Size>[
    Size(360, 800),
    Size(375, 812),
    Size(390, 844),
    Size(411, 901),
    Size(430, 932),
    Size(600, 960),
  ];

  Widget wrap(Size size, LocalStorage storage, Widget child) {
    return ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
        oraclyAiServiceProvider.overrideWithValue(
          const UnconfiguredOraclyAiService(allowsLocalFallback: true),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            padding: const EdgeInsets.only(bottom: 24),
            disableAnimations: true,
          ),
          child: child,
        ),
      ),
    );
  }

  testWidgets('start screen fits the smallest supported phone', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    // Without a surface of its own the harness clamps to 800x600, which is
    // narrower than any supported phone.
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(360, 800)),
          child: Scaffold(
            body: SizedBox(
              width: 360,
              height: 800,
              child: Column(
                children: [
                  Expanded(child: CompanionReferenceIdle(onSelected: (_) {})),
                  CompanionReferenceInputBar(
                    controller: controller,
                    onSend: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text(CompanionCopy.idleTitle), findsOneWidget);
    expect(find.text(CompanionCopy.idleSubtitle), findsOneWidget);
    expect(find.text(CompanionCopy.idleOptional), findsOneWidget);
    expect(CompanionCopy.suggestions.length, greaterThanOrEqualTo(7));
    expect(find.text(CompanionCopy.suggestions.first), findsOneWidget);
    expect(find.text(CompanionCopy.suggestions[1]), findsOneWidget);
    expect(find.text(CompanionCopy.suggestions.last), findsNothing);
    expect(find.text(CompanionCopy.plusLabel), findsOneWidget);
    expect(find.byType(CompanionReferencePlusSlot), findsOneWidget);
    expect(find.byType(CompanionReferenceVoiceSlot), findsOneWidget);
    expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
    expect(find.byIcon(Icons.north_east_rounded), findsOneWidget);
  });

  testWidgets('typed text shows SEND and keyboard submit uses it', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var sent = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompanionReferenceInputBar(
            controller: controller,
            onSend: () => sent++,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
    expect(find.byIcon(Icons.north_east_rounded), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).keyboardType,
      TextInputType.multiline,
    );

    await tester.enterText(find.byType(TextField), 'Selam');
    await tester.pump();
    expect(find.byIcon(Icons.north_east_rounded), findsOneWidget);
    expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.north_east_rounded));
    await tester.pump();
    expect(sent, 1);

    await tester.enterText(find.byType(TextField), 'Selam');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    expect(sent, 2);
  });

  group('OR companion — no overflow', () {
    for (final size in viewports) {
      testWidgets('full page at ${size.width.toInt()}x${size.height.toInt()}', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        SharedPreferences.setMockInitialValues({});
        final storage = await LocalStorage.open();

        await tester.pumpWidget(
          wrap(
            size,
            storage,
            SizedBox(
              width: size.width,
              height: size.height,
              child: const CompanionReferenceScreen(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(tester.takeException(), isNull);
        expect(find.text(CompanionReferenceAppBar.title), findsWidgets);
        expect(find.text('OR REHBERİ'), findsNothing);
        expect(find.byType(CompanionReferenceIdentity), findsOneWidget);
        // Free users meet OR presence + sample talk — not a fake personal result.
        expect(find.text(CompanionCopy.presence), findsOneWidget);
        expect(find.text(CompanionCopy.orPremiumLead), findsOneWidget);
        expect(find.text(CompanionCopy.orPremiumPersonality), findsOneWidget);
        expect(find.text(CompanionCopy.orPremiumSampleLabel), findsOneWidget);
        expect(find.text(CompanionCopy.orPremiumSampleNote), findsOneWidget);
        expect(find.text(ConversationCopy.inputHint), findsNothing);
        expect(find.byType(CompanionReferenceVoiceSlot), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    }
  });
}
