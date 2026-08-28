import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/ai/production/oracly_ai_providers.dart';
import 'package:oracly_new/features/ai/production/unconfigured_oracly_ai_service.dart';
import 'package:oracly_new/features/dream/copy/dream_copy.dart';
import 'package:oracly_new/features/dream/presentation/reference/dream_reference_action_buttons.dart';
import 'package:oracly_new/features/dream/presentation/reference/dream_reference_app_bar.dart';
import 'package:oracly_new/features/dream/presentation/reference/dream_reference_entry_hub.dart';
import 'package:oracly_new/features/dream/presentation/reference/dream_reference_illustration_card.dart';
import 'package:oracly_new/features/dream/presentation/reference/dream_reference_recent_list.dart';
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

  group('Dream reference hub — no overflow', () {
    for (final size in viewports) {
      final label = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('entry hub at $label', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final storage = await LocalStorage.open();
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          wrap(
            size,
            storage,
            SizedBox(
              width: size.width,
              height: size.height,
              child: DreamReferenceEntryHub(
                dreams: const [],
                onWriteTap: _noop,
                onVoiceTap: _noop,
                onDreamTap: (_) {},
              ),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.text(DreamCopy.screenTitle), findsOneWidget);
        expect(find.textContaining('Önizleme'), findsWidgets);
        expect(find.text('Rüyanı Yaz'), findsOneWidget);
        expect(find.text('Sesli Anlat'), findsOneWidget);
        expect(find.text(DreamCopy.previousDreams), findsOneWidget);
        expect(find.text(DreamCopy.noPreviousDreams), findsOneWidget);
        expect(find.byType(DreamReferenceIllustrationCard), findsOneWidget);
        expect(find.byType(DreamReferenceAppBar), findsOneWidget);
        expect(find.byType(DreamReferenceActionButtons), findsOneWidget);
        expect(find.byType(DreamReferenceRecentList), findsOneWidget);
      });
    }
  });
}

void _noop() {}
