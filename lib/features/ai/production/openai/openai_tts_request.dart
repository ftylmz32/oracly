/// Proxy TTS payload — OR identity only, never a provider key or voice name.
library;

import '../../services/prompt_sanitizer.dart';
import 'package:oracly_new/core/l10n/app_locale.dart';
import 'package:oracly_new/core/voice/or_speech_speed.dart';
import 'package:oracly_new/core/voice/oracly_voice_id.dart';
import '../transport/ai_operation.dart';
import '../transport/ai_proxy_request.dart';

abstract final class OpenAiTtsRequest {
  OpenAiTtsRequest._();

  static AiProxyRequest create({
    required String text,
    required String personality,
    String language = 'tr',
    String? voiceId,
    String? speechSpeed,
  }) {
    return AiProxyRequest(
      operation: AiOperation.tts,
      payload: {
        'text': PromptSanitizer.sanitize(text),
        'language': AppLocale.normalize(language),
        'voiceId': OraclyVoiceId.parse(voiceId).wire,
        'speechSpeed': OrSpeechSpeed.parse(speechSpeed).wire,
        if (personality.trim().isNotEmpty) 'personality': personality.trim(),
      },
    );
  }
}
