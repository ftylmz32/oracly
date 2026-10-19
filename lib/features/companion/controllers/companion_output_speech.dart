part of 'companion_output_controller.dart';

extension CompanionOutputSpeech on CompanionOutputController {
  void dropSpoken() {
    _lastSpoken = null;
    _lastGrant = null;
  }

  Future<void> speakIfVoice(String? text, {String? speechGrant}) async {
    if (!mode.isVoice) return;
    final gen = _speakGen;
    try {
      await Future<void>.delayed(Duration.zero);
      if (!mode.isVoice || gen != _speakGen) return;
      final spoken = _spoken(text);
      if (spoken.isEmpty) return;
      _remember(spoken, speechGrant);
      await OraclyTtsGate.speakChat(spoken, speechGrant: _lastGrant);
      if (gen != _speakGen) await OraclyTtsGate.stop();
    } catch (_) {}
    noteSpeech();
  }

  Future<void> speakNow(String text, {String? speechGrant}) async {
    if (!mode.isVoice) return;
    final spoken = _spoken(text);
    if (spoken.isEmpty) return;
    await interrupt();
    final gen = _speakGen;
    _remember(spoken, speechGrant);
    await OraclyTtsGate.speakChat(spoken, speechGrant: _lastGrant);
    if (gen != _speakGen) await OraclyTtsGate.stop();
    noteSpeech();
  }

  Future<void> replay() async {
    final text = _lastSpoken;
    if (text == null || text.isEmpty || !mode.isVoice) return;
    await speakNow(text, speechGrant: _lastGrant);
  }

  void _remember(String spoken, String? speechGrant) {
    _lastSpoken = spoken;
    _lastGrant = OrSpeechGrant.read(speechGrant);
  }
}
