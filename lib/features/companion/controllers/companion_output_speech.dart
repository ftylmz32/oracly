part of 'companion_output_controller.dart';

extension CompanionOutputSpeech on CompanionOutputController {
  void dropSpoken() {
    _lastSpoken = null;
    _lastGrant = null;
  }

  Future<void> speakIfVoice(
    String? text, {
    String? speechGrant,
    int? speechBoundary,
  }) async {
    if (!mode.isVoice) return;
    final boundary = speechBoundary ?? CompanionOutputController.speechBoundary;
    final gen = _speakGen;
    try {
      await Future<void>.delayed(Duration.zero);
      if (!_stillSpeaking(boundary, gen)) return;
      final spoken = _spoken(text);
      if (spoken.isEmpty) return;
      _remember(spoken, speechGrant);
      await OraclyTtsGate.speakChat(spoken, speechGrant: _lastGrant);
      if (!_stillSpeaking(boundary, gen)) {
        await OraclyTtsGate.stop();
        if (boundary != CompanionOutputController.speechBoundary) {
          dropSpoken();
        }
      }
    } catch (_) {}
    if (boundary == CompanionOutputController.speechBoundary) noteSpeech();
  }

  Future<void> speakNow(String text, {String? speechGrant}) async {
    if (!mode.isVoice) return;
    final spoken = _spoken(text);
    if (spoken.isEmpty) return;
    final boundary = CompanionOutputController.speechBoundary;
    await interrupt();
    if (boundary != CompanionOutputController.speechBoundary) return;
    final gen = _speakGen;
    _remember(spoken, speechGrant);
    await OraclyTtsGate.speakChat(spoken, speechGrant: _lastGrant);
    if (!_stillSpeaking(boundary, gen)) {
      await OraclyTtsGate.stop();
      if (boundary != CompanionOutputController.speechBoundary) dropSpoken();
    }
    if (boundary == CompanionOutputController.speechBoundary) noteSpeech();
  }

  bool _stillSpeaking(int boundary, int gen) =>
      mode.isVoice &&
      gen == _speakGen &&
      boundary == CompanionOutputController.speechBoundary;

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
