/// Prefer a real engine/voice when the OS still has cheap Pico leftover.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'oracly_voice_id.dart';

abstract final class OraclyDeviceTtsVoices {
  OraclyDeviceTtsVoices._();

  static const google = 'com.google.android.tts';
  static bool googleBound = false;

  static Future<void> prefer(
    FlutterTts tts,
    String languageCode, [
    OraclyVoiceId? identity,
  ]) async {
    if (kIsWeb) return;
    final locale = localeOf(languageCode);
    await _engine(tts);
    await _voice(tts, locale, identity);
  }

  static String localeOf(String languageCode) {
    final code = languageCode.toLowerCase();
    if (code.startsWith('en')) return 'en-US';
    if (code.startsWith('ru')) return 'ru-RU';
    return 'tr-TR';
  }

  static Map<String, String>? choose({
    required List<Map<String, String>> voices,
    required String locale,
    OraclyVoiceId? identity,
  }) {
    final ranked = [
      for (final voice in voices)
        if (_matches(voice['locale'], locale)) voice,
    ]..sort((a, b) => _weight(a, identity).compareTo(_weight(b, identity)));
    return ranked.isEmpty ? null : ranked.last;
  }

  static Future<void> _engine(FlutterTts tts) async {
    googleBound = false;
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final raw = await tts.getEngines;
      final engines =
          raw is List ? raw.map((e) => '$e').toList() : const <String>[];
      if (engines.any((e) => e == google)) {
        await tts.setEngine(google);
        googleBound = true;
      }
    } catch (_) {}
  }

  static Future<void> _voice(
    FlutterTts tts,
    String locale,
    OraclyVoiceId? identity,
  ) async {
    try {
      final raw = await tts.getVoices;
      if (raw is! List) return;
      final voices = [
        for (final item in raw)
          if (item is Map) item.map((k, v) => MapEntry('$k', '$v')),
      ];
      final best = choose(voices: voices, locale: locale, identity: identity);
      if (best == null) return;
      await tts.setVoice({
        'name': best['name'] ?? '',
        'locale': best['locale'] ?? locale,
      });
    } catch (_) {}
  }

  static bool _matches(String? voiceLocale, String wanted) {
    final have = (voiceLocale ?? '').toLowerCase().replaceAll('_', '-');
    final need = wanted.toLowerCase();
    return have == need || have.startsWith(need.split('-').first);
  }

  static int _weight(Map<String, String> voice, OraclyVoiceId? identity) {
    final name = '${voice['name']} ${voice['locale']}'.toLowerCase();
    var n = 0;
    if (name.contains('wavenet') || name.contains('neural')) n += 12;
    if (name.contains('network')) n += 10;
    if (name.contains('tr-tr-x-') || name.contains('en-us-x-')) n += 6;
    if (name.contains('google')) n += 4;
    if (name.contains('local')) n += 2;
    if (name.contains('pico') ||
        name.contains('svox') ||
        name.contains('compact')) {
      n -= 16;
    }
    final sex = _sex(voice);
    if (identity == null || sex == null) return n;
    final wantLower = identity.prefersLowerRegister;
    if (wantLower == sex) n += 12;
    if (wantLower != sex) n -= 12;
    return n;
  }

  static bool? _sex(Map<String, String> voice) {
    final blob =
        '${voice['gender']} ${voice['name']} ${voice['locale']}'.toLowerCase();
    if (blob.contains('female') || blob.contains('-tf')) return false;
    if (blob.contains('male') || blob.contains('-tm')) return true;
    return null;
  }
}
