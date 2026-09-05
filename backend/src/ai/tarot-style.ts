import type { OpenAiMessage } from '../types.js';
import {
  responseLanguageDirective,
  type AppLanguage,
} from './app-language.js';
import { sanitizeText } from './sanitize.js';

const TAROT_SYSTEM =
  'You are Luna, Oracly\'s reflective Tarot reader. ' +
  'READING_EVIDENCE contains the only cards actually drawn now. Treat card name, spread position, orientation, catalogue meaning and keywords as current-reading evidence. ' +
  'CONTINUITY_OBSERVATIONS is optional historical metadata. It is never proof that a card, symbol, event or feeling exists in the current reading. ' +
  'Never invent a card, orientation, position, past reading, memory, relationship, event, diagnosis or future fact. ' +
  'If continuity is absent or weak, do not say "before", "again", "your recent readings" or equivalent. ' +
  'If continuity is used, frame it cautiously as a recurring recorded theme, then return immediately to current card evidence. ' +
  'No deterministic prophecy, dates, guarantees, medical claims or fear language. Be candid when cards are tense; do not force positivity. ' +
  'Write naturally, specifically and conversationally; avoid fortune-cookie clichés and repeated mystical filler. ' +
  'Return ONLY one JSON object, no markdown.';

export function tarotMessages(
  payload: Record<string, unknown>,
  language: AppLanguage = 'tr',
): OpenAiMessage[] {
  const cards = Array.isArray(payload.cards) ? payload.cards : [];
  const continuity = payload.continuity && typeof payload.continuity === 'object'
    ? payload.continuity
    : null;
  const evidence = {
    spreadLabel: sanitizeText(payload.spreadLabel, 120),
    userQuestion: sanitizeText(payload.userQuestion, 800),
    readingTheme: sanitizeText(payload.readingTheme, 80),
    cards,
  };
  const request = {
    READING_EVIDENCE: evidence,
    ...(continuity ? { CONTINUITY_OBSERVATIONS: continuity } : {}),
  };
  const schema = {
    summary: 'answer-first coherent reading grounded in the spread',
    love: 'only when relevant; otherwise empty string',
    career: 'only when relevant; otherwise empty string',
    money: 'only when relevant; otherwise empty string',
    health: 'card-by-card/position evidence, symbolic only; no medical claims',
    spiritualGuidance: 'reflective layer; no supernatural certainty',
    advice: 'specific practical reflection',
    warnings: 'one or two open questions/cautions, not fear',
    luckyEnergy: 'coherent whole-spread story; not a luck guarantee',
    dailyFocus: 'small practical focus',
    closingMessage: 'natural closing that can invite Luna conversation',
  };
  return [
    {
      role: 'system',
      content: `${TAROT_SYSTEM} ${responseLanguageDirective(language)}`,
    },
    {
      role: 'user',
      content:
        'Interpret this Tarot reading. Keep all claims traceable to READING_EVIDENCE; continuity may personalize but may not create evidence. ' +
        `Required JSON keys and intent: ${JSON.stringify(schema)}\n\n` +
        `INPUT: ${JSON.stringify(request)}`,
    },
  ];
}
