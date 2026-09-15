import type { OpenAiMessage } from '../types.js';
import type { OracleKind } from '../types.js';
import { chatSystem, oracleReadingGrounding, personalityLine, type ChatPersonality } from './chat-style.js';
import { depthLine, type ChatDepth } from './chat-depth.js';
import { historyMessages, type ChatTurn } from './parse-turns.js';
import { coffeeSystem, coffeeUserLead } from './coffee-style.js';
import { sanitizeText, stringList } from './sanitize.js';
import {
  responseLanguageDirective,
  type AppLanguage,
} from './app-language.js';

const ORACLE_SYSTEM = oracleReadingGrounding('tr'); // legacy export for tests
const DREAM_SYSTEM =
  "Sen OR — Oracly'nin sakin rüya yorumcususun. Türkçe yaz. " +
  'Kişisel, sembolik, meraklı ve yere basan bir yansıma yaz. ' +
  'Rüya sözlüğü, tıbbi teşhis ve doğaüstü kesinlik yok. ' +
  'Yalnızca verilen rüya metnini, duygusal tonu ve gerçek kişisel bağlamı kullan. ' +
  'Metinde olmayan sembolü ekleme. ' +
  'Yasak: Yılan = dönüşüm, Anlam:, temsil eder, demektir, kesinlik, tarih, hastalık, ömür. ' +
  'Katmanları karıştırma: ANA HİS rüyanın tonudur, metni tekrar etme; ' +
  'DİKKAT ÇEKEN DETAY anlatılan bir izdir; SEMBOLİK YORUM meraklı bir okumadır; ' +
  'KİŞİSEL BAĞLAM uydurulmaz; AÇIK SORU tektir. ' +
  'Sembolleri tek tek bir sözlük gibi açıklama; anlatıdaki birden çok ayrıntı arasındaki ilişkiyi kur ve bu ilişkiden anlam çıkar; zorlama, yalnızca anlatı destekliyorsa bağla. ' +
  'İki ayrıntıyı yalnızca yan yana anmak yetmez: birinin diğerinin anlamını nasıl değiştirdiğini veya karmaşıklaştırdığını göster. ' +
  'Anlatıda doğrudan belirtilen bir duygu durumu varsa (özellikle "korkmadım", "kaygılı değildim" gibi olumsuzlanmış ifadeler), bunu atmosferden çıkarılan tahminden önce yansıt ve onunla çelişme; anlatının belirtmediği bir duyguyu (ör. anlatılmayan bir yalnızlık) ekleme. ' +
  '"Yeni bir fırsat", "yeni başlangıç", "güzel haberler geliyor", "değişim geliyor", "hedeflerine ulaşacaksın" gibi kalıp ifadeleri yalnızca anlatı açıkça destekliyorsa kullan. ' +
  'Yanıtı yalnızca JSON ver.';

const DREAM_USER_LEAD =
  'Bu rüyayı yorumla. Rüya sözlüğü yazma. Teşhis koyma. Kesin konuşma. ' +
  'JSON: ozet (rüyanın ana hissi; metni kopyalama), ' +
  'semboller (yalnızca metinde geçenler), ' +
  'duygusalTema (rüyanın genel duygusal atmosferi; anlatı cümlelerini olduğu gibi tekrarlama; ' +
  'anlatıda doğrudan belirtilen bir duygu ifadesi varsa -olumsuzlanmış olsa bile- bunu tahmin edilen atmosferden önce yansıt; ' +
  'tek bir duyguya indirgenemiyorsa birden fazla/karışık duygudan söz edebilirsin; anlatının belirtmediği bir duygu uydurma), ' +
  'yorum (en az iki somut ayrıntıyı birbirine bağlayan sembolik okuma; ayrıntılardan birinin diğerinin anlamını nasıl değiştirdiğini ' +
  'veya karmaşıklaştırdığını göster, yalnızca yan yana anma; anlatılan duygusal ipuçlarını yoruma katıştır; ' +
  'metni tekrarlama; X = Y yok; kalıp ve genel ifadelerden kaçın), ' +
  'gunlukYansi (boş bırakma; kişisel geçmiş yoksa yalnızca rüya anlatısına dayanan, ' +
  'temkinli ve uygulanabilir bir günlük yansıma yaz; yorum alanını tekrarlama ve kişisel gerçek uydurma), ' +
  'sonuc (tek açık soru). ' +
  'Metinde olmayan imge ekleme.';


export function chatMessages(
  userMessage: string,
  priorUser: string[],
  styleHint?: string,
  turns: ChatTurn[] = [],
  personality?: ChatPersonality,
  language: AppLanguage = 'tr',
  depth: ChatDepth = 'balanced',
  spoken = false,
): OpenAiMessage[] {
  const hint = sanitizeText(styleHint ?? '', 360);
  const voice = personalityLine(personality, language);
  const system = [
    chatSystem(language),
    responseLanguageDirective(language),
    voice,
    depthLine(depth, spoken, language),
    hint,
  ].filter(Boolean).join(' ');
  return [
    { role: 'system', content: system },
    ...historyMessages(turns, priorUser),
    { role: 'user', content: sanitizeText(userMessage) },
  ];
}

export function oracleMessages(
  kind: OracleKind,
  context: Record<string, unknown>,
  userMessage: string,
  priorUser: string[],
  language: AppLanguage = 'tr',
  turns: ChatTurn[] = [],
  personality?: ChatPersonality,
  styleHint?: string,
  depth: ChatDepth = 'balanced',
  spoken = false,
): OpenAiMessage[] {
  const hint = sanitizeText(styleHint ?? '', 360);
  const voice = personalityLine(personality, language);
  const system = [
    chatSystem(language),
    oracleReadingGrounding(language),
    responseLanguageDirective(language),
    voice,
    depthLine(depth, spoken, language),
    hint,
  ].filter(Boolean).join(' ');
  return [
    { role: 'system', content: system },
    { role: 'user', content: oracleContextBlock(kind, context) },
    ...historyMessages(turns, priorUser),
    { role: 'user', content: sanitizeText(userMessage) },
  ];
}

export function dreamMessages(
  payload: Record<string, unknown>,
  language: AppLanguage = 'tr',
): OpenAiMessage[] {
  const narrative = sanitizeText(payload.narrative);
  const extras = [
    stringList(payload.symbols).length
      ? `Gözlenen semboller: ${stringList(payload.symbols).join(', ')}`
      : '',
    stringList(payload.emotions).length
      ? `Belirtilen duygular: ${stringList(payload.emotions).join(', ')}`
      : '',
  ]
    .filter(Boolean)
    .join('\n');
  const memory = sanitizeText(payload.memorySummary, 220);
  const history = memory
    ? `\n\nİlgili geçmiş bağlam (yalnızca bu rüyanın mevcut ayrıntıları destekliyorsa temkinli kullan; desteklemiyorsa yok say):\n${memory}`
    : '';
  return [
    { role: 'system', content: `${DREAM_SYSTEM} ${responseLanguageDirective(language)}` },
    {
      role: 'user',
      content:
        `${DREAM_USER_LEAD}\n\n` +
        `${narrative}${extras ? `\n\n${extras}` : ''}${history}`,
    },
  ];
}

export function coffeeMessages(
  mimeType: string,
  base64: string,
  language: AppLanguage = 'tr',
): OpenAiMessage[] {
  return [
    { role: 'system', content: `${coffeeSystem(language)} ${responseLanguageDirective(language)}` },
    {
      role: 'user',
      content: [
        {
          type: 'text',
          text:
            coffeeUserLead(language),
        },
        {
          type: 'image_url',
          image_url: { url: `data:${mimeType};base64,${base64}` },
        },
      ],
    },
  ];
}

function oracleContextBlock(
  kind: OracleKind,
  context: Record<string, unknown>,
): string {
  const lines = [`Okuma türü: ${kind}`];
  const text = (key: string) => sanitizeText(context[key]);
  switch (kind) {
    case 'tarot':
      lines.push(
        `Açılım: ${text('spreadLabel')}`,
        `Kartlar:\n${text('cardsSummary')}`,
        `Özet: ${text('interpretationSummary')}`,
      );
      if (text('userQuestion')) lines.push(`Niyet: ${text('userQuestion')}`);
      if (text('fullInterpretation')) lines.push(text('fullInterpretation'));
      break;
    case 'dream':
      lines.push(`Rüya: ${text('narrative')}`);
      if (stringList(context.symbols).length) {
        lines.push(`Semboller: ${stringList(context.symbols).join(', ')}`);
      }
      if (text('analysis')) lines.push(`Yorum: ${text('analysis')}`);
      if (text('fullInterpretation')) lines.push(text('fullInterpretation'));
      break;
    case 'astrology':
      lines.push(
        `Burç: ${text('signLabel')}`,
        `Tür: ${text('readingType') || 'Günlük'}`,
        `Günlük: ${text('daily')}`,
      );
      if (text('fullInterpretation')) lines.push(text('fullInterpretation'));
      break;
    case 'birthChart':
      lines.push(`Güneş: ${text('sunLabel')}`, `Yorum: ${text('interpretation')}`);
      if (text('fullInterpretation')) lines.push(text('fullInterpretation'));
      break;
    case 'coffee':
      if (text('visualObservation')) {
        lines.push(`Görülen izler: ${text('visualObservation')}`);
      }
      lines.push(`Genel: ${text('overall')}`);
      if (stringList(context.symbolNames).length) {
        lines.push(`Semboller: ${stringList(context.symbolNames).join(', ')}`);
      }
      if (text('fullInterpretation')) lines.push(text('fullInterpretation'));
      break;
    case 'palm':
      lines.push('Okuma kaynağı: Palm (el falı) — sembolik yansıma.');
      if (text('handLabel')) lines.push(`El: ${text('handLabel')}`);
      lines.push(`Genel: ${text('overall')}`);
      if (text('heartLine')) {
        lines.push(`Kalp çizgisi (sembolik): ${text('heartLine')}`);
      }
      if (text('headLine')) {
        lines.push(`Zihin çizgisi (sembolik): ${text('headLine')}`);
      }
      if (text('lifeLine')) {
        lines.push(`Yaşam çizgisi (sembolik): ${text('lifeLine')}`);
      }
      if (text('fateLine')) {
        lines.push(`Yön çizgisi (sembolik): ${text('fateLine')}`);
      }
      if (stringList(context.symbols).length) {
        lines.push(`İzler: ${stringList(context.symbols).join(', ')}`);
      }
      if (stringList(context.themes).length) {
        lines.push(`Temalar: ${stringList(context.themes).join(', ')}`);
      }
      if (text('takeaway')) {
        lines.push(`Öne çıkan işaret: ${text('takeaway')}`);
      }
      if (text('fullInterpretation')) lines.push(text('fullInterpretation'));
      lines.push('Not: Sembolik yansıma — tıbbi veya tanısal yorum değildir.');
      break;
  }
  const observed = stringList(context.observedThemes);
  if (observed.length) {
    lines.push(
      `Kayıtlı keşiflerinde tekrar eden sembolik temalar: ${observed.join(', ')}. ` +
        'Bunları yalnızca gerçekten varsa kullan; yoksa "son yorumlarında" deme.',
    );
  }
  return sanitizeText(lines.filter(Boolean).join('\n\n'), 12_000);
}
