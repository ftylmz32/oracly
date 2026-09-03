/// Dream continuous dictation — accumulator, pause/restart, Android generations.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/app_locale.dart';
import 'package:oracly_new/features/dream/controllers/dream_voice_controller.dart';
import 'package:oracly_new/features/dream/copy/dream_copy.dart';
import 'package:oracly_new/features/dream/services/dream_voice_input_port.dart';
import 'package:oracly_new/features/dream/voice/dream_speech_locale.dart';
import 'package:oracly_new/features/dream/voice/dream_voice_failure.dart';
import 'package:oracly_new/features/dream/voice/dream_voice_permission.dart';
import 'package:oracly_new/features/dream/voice/dream_voice_phase.dart';
import 'package:oracly_new/features/dream/voice/dream_voice_transcript.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DreamVoiceTranscript', () {
    test('one uninterrupted sentence via partial then final', () {
      final t = DreamVoiceTranscript();
      t.applyResult('Ruyamda uzun bir yol', false, generation: 1);
      t.applyResult('Ruyamda uzun bir yol vardi.', true, generation: 1);
      expect(t.text, 'Ruyamda uzun bir yol vardi.');
    });

    test('multiple partial results update active segment only', () {
      final t = DreamVoiceTranscript();
      t.applyResult('Ilk', false, generation: 1);
      t.applyResult('Ilk cumle', false, generation: 1);
      expect(t.text, 'Ilk cumle');
    });

    test('pause restart keeps prior segment and appends next', () {
      final t = DreamVoiceTranscript();
      t.applyResult('Birinci cumle.', true, generation: 1);
      t.beginNextGeneration();
      t.applyResult('Ikinci', false, generation: 2);
      t.applyResult('Ikinci cumle.', true, generation: 2);
      expect(t.text, 'Birinci cumle. Ikinci cumle.');
    });

    test('partial-only generation sealed before next generation', () {
      final t = DreamVoiceTranscript();
      t.applyResult('karanlik bir', false, generation: 1);
      t.beginNextGeneration();
      t.applyResult('sonra', false, generation: 2);
      t.applyResult('sonra bir kapi gordum', true, generation: 2);
      expect(t.text, 'karanlik bir sonra bir kapi gordum');
    });

    test('three segments with pauses', () {
      final t = DreamVoiceTranscript();
      t.applyResult('A.', true, generation: 1);
      t.beginNextGeneration();
      t.applyResult('B.', true, generation: 2);
      t.beginNextGeneration();
      t.applyResult('C.', true, generation: 3);
      expect(t.text, 'A. B. C.');
    });

    test('latest segment does not replace previous segments', () {
      final t = DreamVoiceTranscript();
      t.applyResult('Eski metin.', true, generation: 1);
      t.beginNextGeneration();
      t.applyResult('Yeni', false, generation: 2);
      expect(t.text, 'Eski metin. Yeni');
    });

    test('second generation final has no prefix relationship with first', () {
      final t = DreamVoiceTranscript();
      t.applyResult('karanlik bir orman', true, generation: 1);
      t.beginNextGeneration();
      t.applyResult('sonra bir kapi gordum', true, generation: 2);
      expect(t.text, 'karanlik bir orman sonra bir kapi gordum');
    });

    test('duplicate final callback does not duplicate text', () {
      final t = DreamVoiceTranscript();
      t.applyResult('Ayni.', true, generation: 1);
      t.applyResult('Ayni.', true, generation: 1);
      expect(t.text, 'Ayni.');
    });

    test('partial to final transition merges without duplication', () {
      final t = DreamVoiceTranscript();
      t.applyResult('Merhaba dunya', false, generation: 1);
      t.applyResult('Merhaba dunya', true, generation: 1);
      expect(t.text, 'Merhaba dunya');
    });

    test('stale callback from older generation is ignored', () {
      final t = DreamVoiceTranscript();
      t.applyResult('Ilk', false, generation: 1);
      t.beginNextGeneration();
      t.applyResult('Ikinci.', true, generation: 2);
      t.applyResult('Ilk geri gelmesin.', true, generation: 1);
      expect(t.text, 'Ilk Ikinci.');
    });

    test('same words in two generations are kept separately', () {
      final t = DreamVoiceTranscript();
      t.applyResult('evet', true, generation: 1);
      t.beginNextGeneration();
      t.applyResult('evet', true, generation: 2);
      expect(t.text, 'evet evet');
    });
  });

  group('resolveDreamSpeechLocale', () {
    test('selects Turkish, English, and Russian when available', () {
      const locales = ['tr_TR', 'en_US', 'ru_RU'];
      expect(resolveDreamSpeechLocale(locales, AppLocale.tr), 'tr_TR');
      expect(resolveDreamSpeechLocale(locales, AppLocale.en), 'en_US');
      expect(resolveDreamSpeechLocale(locales, AppLocale.ru), 'ru_RU');
    });

    test('returns null when language unsupported on device', () {
      expect(resolveDreamSpeechLocale(const ['tr_TR'], AppLocale.en), isNull);
    });
  });

  group('Android recognition generations', () {
    test('two generations with pause seal full transcript on Durdur', () async {
      final port = _AndroidGenerationFake();
      final voice = DreamVoiceController(port);
      await voice.start();
      await port.playGeneration1();
      await port.playGeneration2();
      await voice.stop();
      expect(voice.transcript, 'karanlik bir orman sonra bir kapi gordum');
    });

    test('new generation partial does not remove generation 1', () async {
      final port = _AndroidGenerationFake();
      final voice = DreamVoiceController(port);
      await voice.start();
      await port.playGeneration1();
      port.emitPartial('sonra');
      expect(voice.transcript, contains('karanlik bir orman'));
      expect(voice.transcript, contains('sonra'));
    });

    test('status done does not clear transcript', () async {
      final port = _AndroidGenerationFake();
      final voice = DreamVoiceController(port);
      await voice.start();
      await port.playGeneration1();
      expect(voice.transcript, 'karanlik bir orman');
      port.endSession();
      await Future<void>.delayed(Duration.zero);
      expect(voice.transcript, 'karanlik bir orman');
    });

    test('restart does not reset transcript', () async {
      final port = _AndroidGenerationFake();
      final voice = DreamVoiceController(port);
      await voice.start();
      await port.playGeneration1();
      port.endSession();
      await Future<void>.delayed(Duration.zero);
      expect(voice.transcript, 'karanlik bir orman');
      expect(voice.phase, DreamVoicePhase.recording);
    });

    test('stale callback from generation 1 after generation 2 starts', () async {
      final port = _AndroidGenerationFake();
      final voice = DreamVoiceController(port);
      await voice.start();
      await port.playGeneration1();
      port.endSession();
      await Future<void>.delayed(Duration.zero);
      port.emitFromGeneration(1, 'karanlik bir orman tekrar', isFinal: true);
      port.emitPartial('sonra');
      port.emitFinal('sonra bir kapi gordum');
      expect(voice.transcript, 'karanlik bir orman sonra bir kapi gordum');
    });

    test('explicit new narration resets old transcript', () async {
      final port = _AndroidGenerationFake();
      final voice = DreamVoiceController(port);
      await voice.start();
      await port.playGeneration1();
      voice.reset();
      await voice.start();
      port.emitFinal('Yeni anlatim.');
      await voice.stop();
      expect(voice.transcript, 'Yeni anlatim.');
    });

    test('explicit Durdur retains all generations', () async {
      final port = _AndroidGenerationFake();
      final voice = DreamVoiceController(port);
      await voice.start();
      await port.playGeneration1();
      await port.playGeneration2();
      await voice.stop();
      expect(voice.phase, DreamVoicePhase.transcribed);
      expect(voice.transcript, 'karanlik bir orman sonra bir kapi gordum');
    });

    test('three generations remain in order', () async {
      final port = _AndroidGenerationFake();
      final voice = DreamVoiceController(port);
      await voice.start();
      port.emitPartial('A');
      port.emitFinal('A.');
      port.endSession();
      await Future<void>.delayed(Duration.zero);
      port.emitPartial('B');
      port.emitFinal('B.');
      port.endSession();
      await Future<void>.delayed(Duration.zero);
      port.emitPartial('C');
      port.emitFinal('C.');
      await voice.stop();
      expect(voice.transcript, 'A. B. C.');
    });

    test('partial-only first generation survives pause before second', () async {
      final port = _AndroidGenerationFake();
      final voice = DreamVoiceController(port);
      await voice.start();
      port.emitPartial('karanlik bir');
      port.endSession();
      await Future<void>.delayed(Duration.zero);
      port.emitPartial('sonra');
      port.emitFinal('sonra bir kapi gordum');
      await voice.stop();
      expect(voice.transcript, 'karanlik bir sonra bir kapi gordum');
    });
  });

  group('DreamVoiceController continuous capture', () {
    test('silence session end restarts without finishing', () async {
      final port = _SegmentFake();
      final voice = DreamVoiceController(port);
      await voice.start();
      port.emitPartial('Ilk');
      port.emitFinal('Ilk cumle.');
      port.endSession();
      await Future<void>.delayed(Duration.zero);
      expect(voice.phase, DreamVoicePhase.recording);
      expect(port.startCount, greaterThan(1));
      expect(voice.transcript, contains('Ilk cumle.'));
    });

    test('explicit stop keeps full accumulated transcript', () async {
      final port = _SegmentFake();
      final voice = DreamVoiceController(port);
      await voice.start();
      port.emitFinal('Birinci.');
      port.endSession();
      await Future<void>.delayed(Duration.zero);
      port.emitFinal('Ikinci.');
      await voice.stop();
      expect(voice.phase, DreamVoicePhase.transcribed);
      expect(voice.transcript, 'Birinci. Ikinci.');
    });

    test('isFinal during capture does not auto-submit review', () async {
      final port = _SegmentFake();
      final voice = DreamVoiceController(port);
      await voice.start();
      port.emitFinal('Sadece bir cumle.');
      expect(voice.phase, DreamVoicePhase.recording);
      await voice.stop();
      expect(voice.phase, DreamVoicePhase.transcribed);
    });

    test('fatal error stops restart loop', () async {
      final port = _SegmentFake(fatalOnRestart: true);
      final voice = DreamVoiceController(port);
      await voice.start();
      port.emitError(DreamVoiceFailure.network());
      expect(voice.phase, DreamVoicePhase.error);
      expect(port.startCount, 1);
    });

    test('recoverable error triggers restart', () async {
      final port = _SegmentFake();
      final voice = DreamVoiceController(port);
      await voice.start();
      port.emitFinal('Korunacak.');
      port.emitError(DreamVoiceFailure.emptyTranscription());
      await Future<void>.delayed(Duration.zero);
      expect(voice.phase, DreamVoicePhase.recording);
      expect(voice.transcript, 'Korunacak.');
      expect(port.startCount, greaterThan(1));
    });

    test('cancel resets session and discards transcript', () async {
      final port = _SegmentFake();
      final voice = DreamVoiceController(port);
      await voice.start();
      port.emitPartial('Silinecek');
      voice.reset();
      expect(voice.phase, DreamVoicePhase.idle);
      expect(voice.transcript, isEmpty);
    });

    test('permission denial does not fabricate text', () async {
      final voice = DreamVoiceController(
        _DeniedFake(DreamVoicePermission.denied),
      );
      await voice.start();
      expect(voice.phase, DreamVoicePhase.error);
      expect(voice.transcript, isEmpty);
      expect(voice.errorMessage, DreamCopy.voicePermissionDenied);
    });

    test('dispose cancels listening', () async {
      final port = _SegmentFake();
      final voice = DreamVoiceController(port);
      await voice.start();
      voice.dispose();
      expect(port.cancelCount, 1);
    });

    test('final transcript unchanged for analysis handoff', () async {
      final port = _SegmentFake();
      final voice = DreamVoiceController(port);
      await voice.start();
      port.emitFinal('Ruyamda deniz vardi.');
      port.endSession();
      await Future<void>.delayed(Duration.zero);
      port.emitFinal('Sonra uyanmistim.');
      await voice.stop();
      final handedOff = voice.transcript;
      voice.editTranscript(handedOff);
      expect(handedOff, 'Ruyamda deniz vardi. Sonra uyanmistim.');
    });

    test('three sentences with pauses accumulate in order', () async {
      final port = _SegmentFake();
      final voice = DreamVoiceController(port);
      await voice.start();
      port.emitFinal('Dun gece karanlik bir ormandaydim');
      port.endSession();
      await Future<void>.delayed(Duration.zero);
      port.emitFinal('Daha sonra uzakta parlak bir kapi gordum');
      port.endSession();
      await Future<void>.delayed(Duration.zero);
      port.emitFinal('Kapiyi acinca uyandim');
      expect(voice.phase, DreamVoicePhase.recording);
      await voice.stop();
      expect(voice.phase, DreamVoicePhase.transcribed);
      expect(voice.transcript, contains('ormandaydim'));
      expect(voice.transcript, contains('kapi gordum'));
      expect(voice.transcript, contains('uyandim'));
    });

    test('restart is bounded at maxRestarts', () async {
      final port = _SegmentFake();
      final voice = DreamVoiceController(port);
      await voice.start();
      for (var i = 0; i < 65; i++) {
        port.endSession();
        await Future<void>.delayed(Duration.zero);
      }
      expect(port.startCount, lessThanOrEqualTo(61));
      expect(voice.phase, DreamVoicePhase.recording);
    });

    test('explicit finish stops restarting', () async {
      final port = _SegmentFake();
      final voice = DreamVoiceController(port);
      await voice.start();
      port.emitFinal('A.');
      await voice.stop();
      expect(voice.phase, DreamVoicePhase.transcribed);
      final count = port.startCount;
      port.endSession();
      await Future<void>.delayed(Duration.zero);
      expect(port.startCount, count);
      expect(voice.phase, DreamVoicePhase.transcribed);
    });

    test('cancel stops restarting', () async {
      final port = _SegmentFake();
      final voice = DreamVoiceController(port);
      await voice.start();
      port.emitFinal('A.');
      voice.reset();
      final count = port.startCount;
      port.endSession();
      await Future<void>.delayed(Duration.zero);
      expect(port.startCount, count);
      expect(voice.phase, DreamVoicePhase.idle);
    });

    test('dispose stops restarting and releases mic', () async {
      final port = _SegmentFake();
      final voice = DreamVoiceController(port);
      await voice.start();
      port.emitFinal('A.');
      voice.dispose();
      expect(port.cancelCount, greaterThan(0));
      port.endSession();
      await Future<void>.delayed(Duration.zero);
      expect(port.startCount, 1);
    });

    test('empty transcript fails safely on explicit finish', () async {
      final port = _SegmentFake();
      final voice = DreamVoiceController(port);
      await voice.start();
      await voice.stop();
      expect(voice.phase, DreamVoicePhase.error);
      expect(voice.errorMessage, DreamCopy.voiceEmpty);
    });

    test('silence during capture never auto-submits review', () async {
      final port = _SegmentFake();
      final voice = DreamVoiceController(port);
      await voice.start();
      port.emitFinal('Ilk cumle.');
      port.endSession();
      await Future<void>.delayed(Duration.zero);
      port.emitFinal('Ikinci cumle.');
      port.endSession();
      await Future<void>.delayed(Duration.zero);
      expect(voice.phase, DreamVoicePhase.recording);
      expect(voice.transcript, 'Ilk cumle. Ikinci cumle.');
    });
  });

  group('Dream voice review handoff', () {
    test('transcript reaches editable review controller on finish', () async {
      final port = _AndroidGenerationFake();
      final voice = DreamVoiceController(port);
      final narrative = TextEditingController();
      voice.addListener(() {
        if (voice.phase == DreamVoicePhase.transcribed &&
            narrative.text != voice.transcript) {
          narrative.text = voice.transcript;
        }
      });
      await voice.start();
      await port.playGeneration1();
      await port.playGeneration2();
      await voice.stop();
      expect(
        narrative.text,
        'karanlik bir orman sonra bir kapi gordum',
      );
      expect(voice.phase, DreamVoicePhase.transcribed);
    });
  });
}

class _DeniedFake implements DreamVoiceInputPort {
  _DeniedFake(this.permission);
  final DreamVoicePermission permission;

  @override
  bool get isAvailable => true;

  @override
  Future<bool> isSpeechAvailable() async => true;

  @override
  Future<DreamVoicePermission> requestPermission() async => permission;

  @override
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    required void Function(DreamVoiceFailure failure) onError,
    VoidCallback? onListeningEnded,
  }) async {}

  @override
  Future<void> stopListening() async {}

  @override
  Future<void> cancelListening() async {}
}

class _SegmentFake implements DreamVoiceInputPort {
  _SegmentFake({this.fatalOnRestart = false});

  final bool fatalOnRestart;
  var startCount = 0;
  var cancelCount = 0;
  void Function(String text, bool isFinal)? _onResult;
  void Function(DreamVoiceFailure failure)? _onError;
  VoidCallback? _onEnded;

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
    startCount += 1;
    if (fatalOnRestart && startCount > 1) {
      onError(DreamVoiceFailure.network());
      return;
    }
    _onResult = onResult;
    _onError = onError;
    _onEnded = onListeningEnded;
  }

  void emitPartial(String text) => _onResult?.call(text, false);

  void emitFinal(String text) => _onResult?.call(text, true);

  void emitError(DreamVoiceFailure failure) => _onError?.call(failure);

  void endSession() => _onEnded?.call();

  @override
  Future<void> stopListening() async {
    _onEnded?.call();
  }

  @override
  Future<void> cancelListening() async {
    cancelCount += 1;
  }
}

/// Models Android STT as separate recognition generations after pause.
class _AndroidGenerationFake implements DreamVoiceInputPort {
  var startCount = 0;
  final List<void Function(String text, bool isFinal)> _generationCallbacks =
      [];
  void Function(String text, bool isFinal)? _onResult;
  VoidCallback? _onEnded;

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
    startCount += 1;
    _generationCallbacks.add(onResult);
    _onResult = onResult;
    _onEnded = onListeningEnded;
  }

  void emitPartial(String text) => _onResult?.call(text, false);

  void emitFinal(String text) => _onResult?.call(text, true);

  void emitFromGeneration(int generation, String text, {required bool isFinal}) {
    if (generation < 1 || generation > _generationCallbacks.length) return;
    _generationCallbacks[generation - 1](text, isFinal);
  }

  void endSession() => _onEnded?.call();

  Future<void> playGeneration1() async {
    emitPartial('karanlik bir');
    emitFinal('karanlik bir orman');
    endSession();
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> playGeneration2() async {
    emitPartial('sonra');
    emitFinal('sonra bir kapi gordum');
    endSession();
    await Future<void>.delayed(Duration.zero);
  }

  @override
  Future<void> stopListening() async {
    _onEnded?.call();
  }

  @override
  Future<void> cancelListening() async {}
}
