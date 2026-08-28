/// Settings copy for OR voice identity — not a second personality catalog.
library;

import '../l10n/l10n.dart';
import 'or_speech_speed.dart';
import 'oracly_voice_id.dart';

abstract final class OraclyVoiceCopy {
  OraclyVoiceCopy._();

  static String _t(String key, String languageCode) =>
      OraclyL10n.t(key, languageCode: languageCode);

  static String previewPhrase(String languageCode) =>
      _t('or.voice.preview_phrase', languageCode);

  static String sectionTitle(String languageCode) =>
      _t('or.voice.section', languageCode);

  static String sectionHint(String languageCode) =>
      _t('or.voice.section_hint', languageCode);

  static String preview(String languageCode) =>
      _t('or.voice.preview', languageCode);

  static String preparing(String languageCode) =>
      _t('or.voice.preparing', languageCode);

  static String title(OraclyVoiceId id, String languageCode) =>
      _t('or.voice.${id.wire}.title', languageCode);

  static String subtitle(OraclyVoiceId id, String languageCode) =>
      _t('or.voice.${id.wire}.subtitle', languageCode);

  static String speedTitle(String languageCode) =>
      _t('or.voice.speed', languageCode);

  static String speedHint(String languageCode) =>
      _t('or.voice.speed_hint', languageCode);

  static String speedLabel(OrSpeechSpeed speed, String languageCode) =>
      _t('or.voice.speed.${speed.wire}', languageCode);
}
