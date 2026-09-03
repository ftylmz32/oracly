/// OR conversation UI — no source/transport/diagnostic copy in the thread.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/copy/ai_source_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/ai/domain/models/ai_message.dart';
import 'package:oracly_new/features/ai/presentation/widgets/ai_source_footnote.dart';
import 'package:oracly_new/features/ai/production/oracly_ai_providers.dart';
import 'package:oracly_new/features/ai/production/unconfigured_oracly_ai_service.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_composer_dock.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_message_bubble.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final labels = <String>[
    AiSourceCopy.sourceLocal,
    AiSourceCopy.sourceLive,
    AiSourceCopy.surfaceLocal,
    AiSourceCopy.surfaceLive,
    AiSourceCopy.thinkingLocal,
    AiSourceCopy.orAskLocal,
    AiSourceCopy.orAskLive,
  ];

  testWidgets('assistant bubble shows only conversational text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CompanionReferenceMessageBubble(
          live: true,
          message: AIMessage(
            id: 'a1',
            role: AIMessageRole.assistant,
            content: 'Burada sakin duruyoruz.',
            createdAt: DateTime(2026, 8, 10),
            metadata: AiSourceCopy.tag(fromAi: false),
          ),
        ),
      ),
    );
    expect(find.text('Burada sakin duruyoruz.'), findsOneWidget);
    for (final label in labels) {
      expect(find.text(label), findsNothing, reason: label);
    }
  });

  testWidgets('composer dock has no AiSourceFootnote', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = LocalStorage(prefs);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          oraclyAiServiceProvider.overrideWithValue(
            const UnconfiguredOraclyAiService(allowsLocalFallback: true),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: CompanionReferenceComposerDock(
              inputController: TextEditingController(),
              onSend: () {},
              enabled: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(AiSourceFootnote), findsNothing);
    for (final label in labels) {
      expect(find.text(label), findsNothing, reason: label);
    }
  });

  test('source metadata helpers remain for internal tagging', () {
    expect(AiSourceCopy.tag(fromAi: false)['source'], AiSourceCopy.metaLocal);
    expect(AiSourceCopy.tag(fromAi: true)['source'], AiSourceCopy.metaLive);
    expect(AiSourceCopy.sourceLocal.toLowerCase(), contains('yerel'));
  });
}

