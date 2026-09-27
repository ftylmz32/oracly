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

export { dreamMessages } from './dream-prompts.js';

const ORACLE_SYSTEM = oracleReadingGrounding('tr'); // legacy export for tests


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
