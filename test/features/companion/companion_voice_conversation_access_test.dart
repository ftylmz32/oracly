/// Voice conversation Premium gate — honest, no fake unlock.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/companion/controllers/companion_output_controller.dart';
import 'package:oracly_new/features/companion/controllers/companion_voice_controller.dart';
import 'package:oracly_new/features/companion/controllers/companion_voice_turn_controller.dart';
import 'package:oracly_new/features/companion/copy/companion_copy.dart';
import 'package:oracly_new/features/companion/models/or_chat_output_mode.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_output_mode.dart';
import 'package:oracly_new/features/companion/services/companion_voice_input_port.dart';
import 'package:oracly_new/features/companion/voice/companion_speech_result.dart';
import 'package:oracly_new/features/companion/voice/companion_voice_failure.dart';
import 'package:oracly_new/features/companion/voice/companion_voice_permission.dart';
import 'package:oracly_new/features/companion/voice/or_voice_turn_phase.dart';

class _SilentStt implements CompanionVoiceInputPort {
  var startCount = 0;
  @override
  bool get isAvailable => true;
  @override
  Future<bool> isSpeechAvailable() async => true;
  @override
  Future<CompanionVoicePermission> requestPermission() async =>
      CompanionVoicePermission.granted;
  @override
  Future<void> startListening({
    required void Function(CompanionSpeechResult result) onResult,
    required void Function(CompanionVoiceFailure failure) onError,
    VoidCallback? onListeningEnded,
  }) async {
    startCount++;
  }
  @override
  Future<void> stopListening() async {}
  @override
  Future<void> cancelListening() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('free tap on SOHBET shows preview and does not unlock',
      (tester) async {
    var mode = OrChatOutputMode.text;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompanionReferenceOutputMode(
            mode: mode,
            conversationAllowed: false,
            onChanged: (next) => mode = next,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text(CompanionCopy.outputConversation));
    await tester.pumpAndSettle();
    expect(
      find.text(CompanionCopy.voiceConversationPreviewTitle),
      findsOneWidget,
    );
    expect(find.text(CompanionCopy.voiceConversationPreviewAside), findsOneWidget);
    expect(mode, OrChatOutputMode.text);
  });

  testWidgets('premium tap on SOHBET unlocks conversation mode', (tester) async {
    var mode = OrChatOutputMode.text;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompanionReferenceOutputMode(
            mode: mode,
            conversationAllowed: true,
            onChanged: (next) => mode = next,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text(CompanionCopy.outputConversation));
    await tester.pump();
    expect(mode, OrChatOutputMode.conversation);
    expect(find.text(CompanionCopy.voiceConversationPreviewTitle), findsNothing);
  });

  test('turn stays inactive when conversation is not activated', () {
    var mode = OrChatOutputMode.conversation;
    final output = CompanionOutputController(
      persistMode: (next) async => mode = next,
      readMode: () => mode,
    );
    final voice = CompanionVoiceController(_SilentStt());
    final turn = CompanionVoiceTurnController(voice: voice, output: output);
    turn.setActive(false);
    expect(turn.isActive, isFalse);
    expect(turn.phase, OrVoiceTurnPhase.ready);
    turn.dispose();
    voice.dispose();
    output.dispose();
  });

  test('preview copy names Premium honestly without continuous listening', () {
    expect(
      CompanionCopy.voiceConversationPreviewAside.toLowerCase(),
      contains('premium'),
    );
    expect(
      CompanionCopy.voiceConversationDemoted.toLowerCase(),
      contains('premium'),
    );
    expect(
      CompanionCopy.voiceConversationPreviewBody.toLowerCase(),
      isNot(contains('sürekli dinleme açık')),
    );
  });
}
