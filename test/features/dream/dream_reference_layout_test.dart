import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/production/oracly_ai_providers.dart';
import 'package:oracly_new/features/ai/production/unconfigured_oracly_ai_service.dart';
import 'package:oracly_new/features/dream/copy/dream_copy.dart';
import 'package:oracly_new/features/dream/models/dream_entry_context.dart';
import 'package:oracly_new/features/dream/presentation/reference/dream_reference_app_bar.dart';
import 'package:oracly_new/features/dream/presentation/reference/dream_reference_entry_view.dart';
import 'package:oracly_new/features/dream/presentation/reference/dream_reference_entry_hero.dart';
import 'package:oracly_new/features/dream/presentation/reference/dream_entry_input_card.dart';
import 'package:oracly_new/features/dream/presentation/reference/dream_entry_context_chips.dart';
import 'package:oracly_new/shared/widgets/oracly_gold_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const viewports = <Size>[
    Size(320, 568),
    Size(360, 640),
    Size(360, 800),
    Size(390, 844),
    Size(412, 915),
    Size(430, 932),
  ];

  setUp(() => OraclyL10n.bind('tr'));

  Widget wrap(Size size, LocalStorage storage, Widget child) {
    return ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
        oraclyAiServiceProvider.overrideWithValue(
          const UnconfiguredOraclyAiService(allowsLocalFallback: true),
        ),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            padding: const EdgeInsets.only(bottom: 24),
          ),
          child: Scaffold(body: child),
        ),
      ),
    );
  }

  group('Dream reference entry — approved layout', () {
    for (final size in viewports) {
      final label = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('entry view at $label', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final storage = await LocalStorage.open();
        final controller = TextEditingController();
        addTearDown(controller.dispose);
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          wrap(
            size,
            storage,
            SizedBox(
              width: size.width,
              height: size.height,
              child: DreamReferenceEntryView(
                controller: controller,
                selectedChips: const {},
                guidedAnswers: const {},
                onChipToggle: (_) {},
                onGuidedChanged: (_, _) {},
                onVoiceTap: () {},
                onSubmit: () {},
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text(DreamCopy.screenTitle), findsOneWidget);
        expect(find.text(DreamCopy.heroHeadline), findsOneWidget);
        expect(find.text(DreamCopy.heroSubline), findsOneWidget);
        expect(find.textContaining(DreamCopy.inputPrompt), findsOneWidget);
        expect(find.byType(DreamReferenceEntryHero), findsOneWidget);
        expect(find.byType(DreamEntryInputCard), findsOneWidget);
        expect(find.byType(DreamEntryContextChips), findsOneWidget);
        expect(find.byType(DreamReferenceAppBar), findsOneWidget);
        expect(find.byType(OraclyGoldButton), findsOneWidget);
        expect(find.text(DreamCopy.submitCta), findsOneWidget);
        expect(find.text(DreamCopy.previousDreams), findsNothing);
      });
    }

    testWidgets('context chips toggle and guided expansion', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();
      final controller = TextEditingController();
      var chips = <DreamEntryChipId>{};
      addTearDown(controller.dispose);
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrap(
          const Size(390, 844),
          storage,
          StatefulBuilder(
            builder: (context, setState) => DreamReferenceEntryView(
              controller: controller,
              selectedChips: chips,
              guidedAnswers: const {},
              onChipToggle: (chip) => setState(() {
                if (chips.contains(chip)) {
                  chips.remove(chip);
                } else {
                  chips.add(chip);
                }
              }),
              onGuidedChanged: (_, _) {},
              onVoiceTap: () {},
              onSubmit: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text(DreamCopy.chipNightmare));
      await tester.pump();
      expect(chips, contains(DreamEntryChipId.nightmare));

      await tester.ensureVisible(find.text(DreamCopy.guidedWho));
      await tester.tap(find.text(DreamCopy.guidedWho));
      await tester.pump();
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('CTA reachable with keyboard on short phone', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();
      final controller = TextEditingController(
        text: 'Karanlik bir ormandaydim ve sessizlik vardi',
      );
      addTearDown(controller.dispose);
      const size = Size(360, 640);
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageProvider.overrideWithValue(storage),
            oraclyAiServiceProvider.overrideWithValue(
              const UnconfiguredOraclyAiService(allowsLocalFallback: true),
            ),
          ],
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                size: size,
                viewInsets: EdgeInsets.only(bottom: 280),
                padding: EdgeInsets.only(bottom: 24),
              ),
              child: Scaffold(
                resizeToAvoidBottomInset: true,
                body: DreamReferenceEntryView(
                  controller: controller,
                  selectedChips: const {},
                  guidedAnswers: const {},
                  onChipToggle: (_) {},
                  onGuidedChanged: (_, _) {},
                  onVoiceTap: () {},
                  onSubmit: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.ensureVisible(find.text(DreamCopy.submitCta));
      await tester.pump();
      expect(find.text(DreamCopy.submitCta), findsOneWidget);
    });
  });
}
