/// OR voice identity + output mode labels — TR / EN / RU.
library;

import '../l10n_keys.dart';
import '../l10n_triple.dart';

const kL10nOrVoice = <String, L10nTriple>{
  L10nKeys.sectionOutput: L10nTriple('LUNA’NIN YANITI', 'LUNA OUTPUT', 'ОТВЕТ LUNA'),
  L10nKeys.outputTitle: L10nTriple(
    'Luna’nın yanıt biçimi',
    'Luna reply mode',
    'Режим ответа Luna',
  ),
  L10nKeys.outputSubtitle: L10nTriple(
    'Yalnızca yazı, sesli yanıt veya sesli sohbet. Mikrofon yalnız dokununca açılır.',
    'Text only, voice replies, or voice conversation. Mic opens only when you tap.',
    'Только текст, голосовые ответы или диалог. Микрофон — только по нажатию.',
  ),
  L10nKeys.orDepthTitle: L10nTriple(
    'Yanıt derinliği',
    'Reply depth',
    'Глубина ответа',
  ),
  L10nKeys.orDepthSubtitle: L10nTriple(
    'Uzunluk: kısa, dengeli veya derin. Kişilik değişmez.',
    'Length: very short, short, balanced/medium, or deep. Personality stays the same.',
    'Длина: коротко, уравновешенно или глубоко. Характер тот же.',
  ),
  'or.depth.very_short': L10nTriple('ÇOK KISA', 'VERY SHORT', 'ОЧЕНЬ КОРОТКО'),
  'or.depth.short': L10nTriple('KISA', 'SHORT', 'КОРОТКО'),
  'or.depth.balanced': L10nTriple('DENGELİ', 'BALANCED', 'БАЛАНС'),
  'or.depth.deep': L10nTriple('DERİN', 'DEEP', 'ГЛУБОКО'),
  'or.voice.section': L10nTriple('Luna Sesi', 'Luna Voice', 'Голос Luna'),
  'or.voice.section_hint': L10nTriple(
    'Aynı Luna. Dört ifade — dört karakter değil.',
    'The same Luna. Four expressions — not four characters.',
    'Та же Luna. Четыре выражения — не четыре персонажа.',
  ),
  'or.voice.preview': L10nTriple('Önizle', 'Preview', 'Проба'),
  'or.voice.preparing': L10nTriple(
    'Hazırlanıyor…',
    'Preparing…',
    'Подготовка…',
  ),
  'or.voice.preview_phrase': L10nTriple(
    'Selam. Buradayım. Şimdi nasılsın?',
    "Hello. I'm here. How are you now?",
    'Привет. Я здесь. Как ты сейчас?',
  ),
  'or.voice.warm.title': L10nTriple('SICAK', 'WARM', 'ТЁПЛЫЙ'),
  'or.voice.warm.subtitle': L10nTriple(
    'Luna’nın sıcak ifadesi — yakın ve açık.',
    'Luna’s warm expression — close and clear.',
    'Тёплое выражение Luna — близкое и ясное.',
  ),
  'or.voice.calm.title': L10nTriple('SAKİN', 'CALM', 'СПОКОЙНЫЙ'),
  'or.voice.calm.subtitle': L10nTriple(
    'Luna’nın sakin ifadesi — ölçülü ve yumuşak.',
    'Luna’s calm expression — measured and soft.',
    'Спокойное выражение Luna — сдержанное и мягкое.',
  ),
  'or.voice.deep.title': L10nTriple('DERİN', 'DEEP', 'ГЛУБОКИЙ'),
  'or.voice.deep.subtitle': L10nTriple(
    'Luna’nın derin ifadesi — alçak ve dengeli.',
    'Luna’s deep expression — lower and balanced.',
    'Глубокое выражение Luna — ниже и ровное.',
  ),
  'or.voice.bright.title': L10nTriple('PARLAK', 'BRIGHT', 'СВЕТЛЫЙ'),
  'or.voice.bright.subtitle': L10nTriple(
    'Luna’nın parlak ifadesi — net ve hafif.',
    'Luna’s bright expression — clear and light.',
    'Светлое выражение Luna — ясное и лёгкое.',
  ),
  'or.voice.speed': L10nTriple(
    'Konuşma hızı',
    'Speech speed',
    'Скорость речи',
  ),
  'or.voice.speed_hint': L10nTriple(
    'Doğal varsayılan. Hızlı hâlâ anlaşılır kalır.',
    'Natural by default. Fast stays intelligible.',
    'По умолчанию естественно. Быстрый остаётся понятным.',
  ),
  'or.voice.speed.slow': L10nTriple('YAVAŞ', 'SLOW', 'МЕДЛЕННО'),
  'or.voice.speed.normal': L10nTriple('NORMAL', 'NORMAL', 'ОБЫЧНО'),
  'or.voice.speed.fast': L10nTriple('HIZLI', 'FAST', 'БЫСТРО'),
};
