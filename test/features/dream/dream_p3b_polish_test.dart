/// P3B — voice draft honesty, character limit, and close label.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/dream/controllers/dream_voice_controller.dart';
import 'package:oracly_new/features/dream/copy/dream_copy.dart';
import 'package:oracly_new/features/dream/models/dream_entry_context.dart';
import 'package:oracly_new/features/dream/models/dream_entry_selection.dart';
import 'package:oracly_new/features/dream/presentation/reference/dream_entry_input_card.dart';
import 'package:oracly_new/features/dream/services/dream_voice_input_port.dart';
import 'package:oracly_new/features/dream/voice/dream_voice_draft.dart';
import 'package:oracly_new/features/dream/voice/dream_voice_failure.dart';
import 'package:oracly_new/features/dream/voice/dream_voice_permission.dart';
import 'package:oracly_new/features/dream/voice/dream_voice_phase.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => OraclyL10n.bind('tr'));

  const kept = 'Rüyamda uzun bir yol vardı.';

  test('denied listen-again keeps the review transcript', () async {
    final narrative = TextEditingController(text: kept);
    final voice = DreamVoiceController(_Port());
    await DreamVoiceDraft.listenAgain(
      askMicrophone: () async => false,
      voice: voice,
    );
    expect(narrative.text, kept);
    expect(voice.phase, DreamVoicePhase.idle);
  });

  test('a new recording replaces the review only after it starts', () async {
    final voice = DreamVoiceController(_Port());
    await voice.start();
    await voice.stop();
    expect(voice.phase, DreamVoicePhase.transcribed);
    final narrative = TextEditingController(text: voice.transcript);
    await DreamVoiceDraft.listenAgain(
      askMicrophone: () async => true,
      voice: voice,
    );
    expect(voice.phase, DreamVoicePhase.recording);
    DreamVoiceDraft.onPhase(
      narrative: narrative,
      from: DreamVoicePhase.transcribed,
      next: voice,
    );
    expect(narrative.text, isEmpty);
  });

  test('cancelling the review does not leak into Write', () async {
    final voice = DreamVoiceController(_Port());
    await voice.start();
    await voice.stop();
    final narrative = TextEditingController(text: voice.transcript);
    DreamVoiceDraft.abandon(narrative: narrative, voice: voice);
    expect(voice.phase, DreamVoicePhase.idle);
    expect(narrative.text, isEmpty);
  });

  test('cancelling a recording keeps text that was already typed', () async {
    final voice = DreamVoiceController(_Port());
    await voice.start();
    final narrative = TextEditingController(text: kept);
    DreamVoiceDraft.abandon(narrative: narrative, voice: voice);
    expect(narrative.text, kept);
  });

  test('result close does not claim a second save', () {
    expect(DreamCopy.closeReading, 'Kapat');
    expect(DreamCopy.saveAndClose, 'Kaydet ve kapat');
    expect(DreamCopy.closeReading, isNot(contains('Kaydet')));
    OraclyL10n.bind('en');
    expect(DreamCopy.closeReading, 'Close');
    OraclyL10n.bind('ru');
    expect(DreamCopy.closeReading, 'Закрыть');
  });

  test('edit restores the stored chips and guided answers', () {
    const entry = DreamEntrySelection(
      chips: [DreamEntryChipId.nightmare],
      guided: {DreamGuidedQuestionId.where: 'eski ev'},
    );
    final chips = <DreamEntryChipId>{DreamEntryChipId.clear};
    final guided = <DreamGuidedQuestionId, String>{
      DreamGuidedQuestionId.who: 'annem',
    };
    entry.applyTo(chips: chips, guided: guided);
    expect(chips, {DreamEntryChipId.nightmare});
    expect(guided[DreamGuidedQuestionId.where], 'eski ev');
    expect(guided.containsKey(DreamGuidedQuestionId.who), isFalse);
  });

  test('the stated character maximum is the field maximum', () {
    expect(DreamEntryContext.narrativeMaxLength, 1000);
    expect(DreamCopy.charLimit(12), '12/1000');
  });

  testWidgets('write field enforces 1000 and fits at 320', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DreamEntryInputCard(
            controller: TextEditingController(),
            onVoiceTap: () {},
          ),
        ),
      ),
    );
    expect(tester.widget<TextField>(find.byType(TextField)).maxLength, 1000);
    expect(find.text('0/1000'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _Port implements DreamVoiceInputPort {
  void Function(String text, bool isFinal)? _onResult;
  VoidCallback? _ended;

  @override
  bool get isAvailable => true;

  @override
  Future<bool> isSpeechAvailable() async => true;

  @override
  Future<DreamVoicePermission> requestPermission() async =>
      DreamVoicePermission.granted;

  @override
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    required void Function(DreamVoiceFailure failure) onError,
    VoidCallback? onListeningEnded,
  }) async {
    _onResult = onResult;
    _ended = onListeningEnded;
    onResult('kısmi', false);
  }

  @override
  Future<void> stopListening() async {
    _onResult?.call('Rüyamda uzun bir yol vardı.', true);
    _ended?.call();
  }

  @override
  Future<void> cancelListening() async {}
}
