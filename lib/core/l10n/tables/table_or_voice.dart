/// OR voice identity + output mode labels — TR / EN / RU.
library;

import '../l10n_keys.dart';
import '../l10n_triple.dart';

const kL10nOrVoice = <String, L10nTriple>{
  L10nKeys.sectionOutput: L10nTriple('OR YANIT', 'OR OUTPUT', 'ОТВЕТ OR'),
  L10nKeys.outputTitle: L10nTriple(
    'OR yanıt biçimi',
    'OR reply mode',
    'Режим ответа OR',
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
  'or.voice.section': L10nTriple('OR Sesi', 'OR Voice', 'Голос OR'),
  'or.voice.section_hint': L10nTriple(
    'Aynı OR. Dört ifade — dört karakter değil.',
    'The same OR. Four expressions — not four characters.',
    'Тот же OR. Четыре выражения — не четыре персонажа.',
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
    'OR’ın sıcak ifadesi — yakın ve açık.',
    'OR’s warm expression — close and clear.',
    'Тёплое выражение OR — близкое и ясное.',
  ),
  'or.voice.calm.title': L10nTriple('SAKİN', 'CALM', 'СПОКОЙНЫЙ'),
  'or.voice.calm.subtitle': L10nTriple(
    'OR’ın sakin ifadesi — ölçülü ve yumuşak.',
    'OR’s calm expression — measured and soft.',
    'Спокойное выражение OR — сдержанное и мягкое.',
  ),
  'or.voice.deep.title': L10nTriple('DERİN', 'DEEP', 'ГЛУБОКИЙ'),
  'or.voice.deep.subtitle': L10nTriple(
    'OR’ın derin ifadesi — alçak ve dengeli.',
    'OR’s deep expression — lower and balanced.',
    'Глубокое выражение OR — ниже и ровное.',
  ),
  'or.voice.bright.title': L10nTriple('PARLAK', 'BRIGHT', 'СВЕТЛЫЙ'),
  'or.voice.bright.subtitle': L10nTriple(
    'OR’ın parlak ifadesi — net ve hafif.',
    'OR’s bright expression — clear and light.',
    'Светлое выражение OR — ясное и лёгкое.',
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
