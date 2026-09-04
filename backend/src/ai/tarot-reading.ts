import type { AppConfig } from '../config.js';
import { ErrorCode, fail } from '../errors.js';
import type { OpenAiTransport } from './openai-transport.js';
import { asRecord, sanitizeText, stringList } from './sanitize.js';
import type { AppLanguage } from './app-language.js';

export type TarotAnalysisCard = {
  cardId: number;
  cardName: string;
  positionLabel: string;
  positionKey: string;
  isReversed: boolean;
  meaning: string;
  keywords: string[];
};

export type TarotJourneyEvidence = {
  recurringThemes: string[];
  priorReadingCount: number;
  hasPriorNotes: boolean;
  priorOpenings: string[];
  revisitPriorExcerpt?: string;
  revisitInstruction?: string;
};

export type TarotAnalysisInput = {
  sessionId: string;
  spreadLabel: string;
  readingTheme?: string;
  userQuestion?: string;
  cards: TarotAnalysisCard[];
  journey?: TarotJourneyEvidence;
};

type TarotAnalysisNarrative = {
  summary: string;
  love: string;
  career: string;
  money: string;
  health: string;
  spiritualGuidance: string;
  advice: string;
  warnings: string;
  luckyEnergy: string;
  dailyFocus: string;
  closingMessage: string;
  referencedCardIds: number[];
  referencedPriorThemes: string[];
  continuityUsed: 'none' | 'theme' | 'revisit';
};

const TAROT_ANALYSIS_SCHEMA: Record<string, unknown> = {
  type: 'object',
  additionalProperties: false,
  required: [
    'summary',
    'love',
    'career',
    'money',
    'health',
    'spiritualGuidance',
    'advice',
    'warnings',
    'luckyEnergy',
    'dailyFocus',
    'closingMessage',
    'referencedCardIds',
    'referencedPriorThemes',
    'continuityUsed',
  ],
  properties: {
    summary: { type: 'string' },
    love: { type: 'string' },
    career: { type: 'string' },
    money: { type: 'string' },
    health: { type: 'string' },
    spiritualGuidance: { type: 'string' },
    advice: { type: 'string' },
    warnings: { type: 'string' },
    luckyEnergy: { type: 'string' },
    dailyFocus: { type: 'string' },
    closingMessage: { type: 'string' },
    referencedCardIds: {
      type: 'array',
      items: { type: 'integer' },
      maxItems: 10,
    },
    referencedPriorThemes: {
      type: 'array',
      items: { type: 'string' },
      maxItems: 4,
    },
    continuityUsed: {
      type: 'string',
      enum: ['none', 'theme', 'revisit'],
    },
  },
};

const CERTAINTY_BLOCKLIST = [
  'kesinlikle olacak',
  'mutlaka olacak',
  'kesin olacak',
  'garanti',
  'you will definitely',
  'it will definitely',
  'точно будет',
  'обязательно будет',
];

export function validateTarotAnalysisPayload(
  payload: Record<string, unknown>,
): TarotAnalysisInput {
  const sessionId = sanitizeText(payload.sessionId, 120);
  const spreadLabel = sanitizeText(payload.spreadLabel, 120);
  if (!sessionId || !spreadLabel) fail(ErrorCode.invalidRequest);

  const rawCards = Array.isArray(payload.cards) ? payload.cards : [];
  if (rawCards.length < 1 || rawCards.length > 10) {
    fail(ErrorCode.invalidRequest);
  }
  const cards: TarotAnalysisCard[] = [];
  const seenIds = new Set<number>();
  for (const raw of rawCards) {
    const card = asRecord(raw);
    if (!card) fail(ErrorCode.invalidRequest);
    const cardId = Number(card.cardId);
    const cardName = sanitizeText(card.cardName, 100);
    const positionLabel = sanitizeText(card.positionLabel, 100);
    const positionKey = sanitizeText(card.positionKey, 80);
    const meaning = sanitizeText(card.meaning, 900);
    if (
      !Number.isInteger(cardId) ||
      cardId < 0 ||
      cardId > 999 ||
      seenIds.has(cardId) ||
      !cardName ||
      !positionLabel ||
      !meaning
    ) {
      fail(ErrorCode.invalidRequest);
    }
    seenIds.add(cardId);
    cards.push({
      cardId,
      cardName,
      positionLabel,
      positionKey: positionKey || `pos_${cards.length}`,
      isReversed: card.isReversed === true,
      meaning,
      keywords: stringList(card.keywords, 8),
    });
  }

  const readingTheme = sanitizeText(payload.readingTheme, 80) || undefined;
  const userQuestion = sanitizeText(payload.userQuestion, 800) || undefined;
  const journeyRecord = asRecord(payload.journey);
  let journey: TarotJourneyEvidence | undefined;
  if (journeyRecord) {
    const recurringThemes = stringList(journeyRecord.recurringThemes, 4);
    const priorOpenings = stringList(journeyRecord.priorOpenings, 4);
    const countRaw = Number(journeyRecord.priorReadingCount ?? 0);
    const priorReadingCount = Number.isFinite(countRaw)
      ? Math.max(0, Math.min(10_000, Math.floor(countRaw)))
      : 0;
    const revisitPriorExcerpt =
      sanitizeText(journeyRecord.revisitPriorExcerpt, 700) || undefined;
    const revisitInstruction =
      sanitizeText(journeyRecord.revisitInstruction, 360) || undefined;
    journey = {
      recurringThemes,
      priorReadingCount,
      hasPriorNotes: journeyRecord.hasPriorNotes === true,
      priorOpenings,
      revisitPriorExcerpt,
      revisitInstruction,
    };
  }

  return {
    sessionId,
    spreadLabel,
    readingTheme,
    userQuestion,
    cards,
    journey,
  };
}

export async function runTarotAnalysis(
  config: AppConfig,
  transport: OpenAiTransport,
  input: TarotAnalysisInput,
  language: AppLanguage,
): Promise<Record<string, unknown>> {
  const model = config.openaiReadingWriterModel;
  if (!model || !config.openaiAllowedModels.includes(model)) {
    fail(ErrorCode.noConfiguration);
  }

  const evidence = JSON.stringify({
    sessionId: input.sessionId,
    spreadLabel: input.spreadLabel,
    readingTheme: input.readingTheme ?? '',
    userQuestion: input.userQuestion ?? '',
    cards: input.cards,
    journey: input.journey ?? null,
  });

  let narrative = await generate(
    transport,
    model,
    tarotSystem(language),
    tarotUser(evidence),
  );
  let violation = bindTarotNarrative(narrative, input);
  if (violation) {
    narrative = await generate(
      transport,
      model,
      tarotRepairSystem(language),
      tarotRepairUser(evidence, narrative, violation),
    );
    violation = bindTarotNarrative(narrative, input);
    if (violation) fail(ErrorCode.invalidResponse, { violation });
  }

  return toPublicTarot(narrative);
}

async function generate(
  transport: OpenAiTransport,
  model: string,
  system: string,
  user: string,
): Promise<TarotAnalysisNarrative> {
  const raw = await transport.complete({
    model,
    messages: [
      { role: 'system', content: system },
      { role: 'user', content: user },
    ],
    jsonSchema: { name: 'tarot_analysis', schema: TAROT_ANALYSIS_SCHEMA },
    temperature: undefined,
  });
  try {
    return JSON.parse(raw) as TarotAnalysisNarrative;
  } catch {
    fail(ErrorCode.invalidResponse);
  }
}

function tarotSystem(language: AppLanguage): string {
  const languageLine =
    language === 'en'
      ? 'Write in English.'
      : language === 'ru'
        ? 'Write in Russian.'
        : 'Türkçe yaz.';
  return [
    "You are Luna, Oracly's grounded tarot reader.",
    languageLine,
    'Use only the supplied cards, positions, meanings, question/theme, and verified journey evidence.',
    'Never invent a prior reading, prior card, relationship fact, event, date, diagnosis, or future certainty.',
    'A previous theme may be mentioned only when it exists in journey.recurringThemes.',
    'A revisit may be mentioned only when a revisitPriorExcerpt exists.',
    'Do not turn tarot into deterministic fortune telling. Prefer reflective probability and concrete present-tense guidance.',
    'Avoid generic mystical filler, repeated openings, and phrases like the universe is telling you.',
    'Make the reading feel like one coherent human conversation, not eleven unrelated mini horoscopes.',
    'If the reading theme does not call for a section such as love/career/money, that section may be empty.',
    'health is not medical advice; use it only as non-medical wellbeing/reflection or leave it empty.',
    'Return JSON only and report exactly which supplied card ids and prior themes you relied on.',
  ].join(' ');
}

function tarotUser(evidenceJson: string): string {
  return [
    'Write a grounded Tarot interpretation from this trusted evidence packet.',
    'summary should answer the reading first. advice/dailyFocus should be usable. closingMessage should naturally invite reflection or a Luna follow-up without sales language.',
    'When there is no meaningful verified history, set continuityUsed="none" and referencedPriorThemes=[].',
    'Evidence:',
    evidenceJson,
  ].join('\n\n');
}

function tarotRepairSystem(language: AppLanguage): string {
  return `${tarotSystem(language)} You are repairing one rejected JSON result. Correct only the grounding violation and return the complete JSON object again.`;
}

function tarotRepairUser(
  evidenceJson: string,
  rejected: TarotAnalysisNarrative,
  violation: string,
): string {
  return [
    `Violation: ${violation}`,
    `Trusted evidence: ${evidenceJson}`,
    `Rejected JSON: ${JSON.stringify(rejected)}`,
  ].join('\n\n');
}

function bindTarotNarrative(
  narrative: TarotAnalysisNarrative,
  input: TarotAnalysisInput,
): string | null {
  if (!narrative || typeof narrative !== 'object') return 'not_object';
  const requiredText = [
    narrative.summary,
    narrative.advice,
    narrative.closingMessage,
  ];
  if (requiredText.some((value) => typeof value !== 'string' || value.trim().length < 8)) {
    return 'missing_core_text';
  }
  const allText = [
    narrative.summary,
    narrative.love,
    narrative.career,
    narrative.money,
    narrative.health,
    narrative.spiritualGuidance,
    narrative.advice,
    narrative.warnings,
    narrative.luckyEnergy,
    narrative.dailyFocus,
    narrative.closingMessage,
  ].filter((value): value is string => typeof value === 'string').join(' ').toLowerCase();
  if (CERTAINTY_BLOCKLIST.some((phrase) => allText.includes(phrase))) {
    return 'certainty_claim';
  }

  if (!Array.isArray(narrative.referencedCardIds) || narrative.referencedCardIds.length < 1) {
    return 'missing_card_evidence';
  }
  const allowedCardIds = new Set(input.cards.map((card) => card.cardId));
  for (const id of narrative.referencedCardIds) {
    if (!Number.isInteger(id) || !allowedCardIds.has(id)) return 'unknown_card_reference';
  }

  const allowedThemes = new Map(
    (input.journey?.recurringThemes ?? []).map((theme) => [theme.toLocaleLowerCase(), theme]),
  );
  if (!Array.isArray(narrative.referencedPriorThemes)) return 'invalid_theme_references';
  for (const theme of narrative.referencedPriorThemes) {
    if (typeof theme !== 'string' || !allowedThemes.has(theme.trim().toLocaleLowerCase())) {
      return 'unknown_prior_theme';
    }
  }

  const hasRevisit = Boolean(input.journey?.revisitPriorExcerpt?.trim());
  const hasThemeHistory = (input.journey?.recurringThemes.length ?? 0) > 0;
  const hasMeaningfulHistory = hasRevisit || hasThemeHistory;
  if (!hasMeaningfulHistory) {
    if (narrative.continuityUsed !== 'none' || narrative.referencedPriorThemes.length > 0) {
      return 'invented_continuity';
    }
  }
  if (narrative.continuityUsed === 'revisit' && !hasRevisit) return 'invented_revisit';
  if (narrative.continuityUsed === 'theme' && narrative.referencedPriorThemes.length < 1) {
    return 'unsubstantiated_theme_continuity';
  }
  return null;
}

function toPublicTarot(narrative: TarotAnalysisNarrative): Record<string, unknown> {
  return {
    summary: sanitizeText(narrative.summary, 2000),
    love: sanitizeText(narrative.love, 1600),
    career: sanitizeText(narrative.career, 1600),
    money: sanitizeText(narrative.money, 1600),
    health: sanitizeText(narrative.health, 1600),
    spiritualGuidance: sanitizeText(narrative.spiritualGuidance, 1600),
    advice: sanitizeText(narrative.advice, 1800),
    warnings: sanitizeText(narrative.warnings, 1600),
    luckyEnergy: sanitizeText(narrative.luckyEnergy, 1800),
    dailyFocus: sanitizeText(narrative.dailyFocus, 1600),
    closingMessage: sanitizeText(narrative.closingMessage, 1600),
  };
}
