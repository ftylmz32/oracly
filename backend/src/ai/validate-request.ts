import { ErrorCode, fail } from '../errors.js';
import {
  OPERATIONS,
  ORACLE_KINDS,
  type AiOperation,
  type OracleKind,
} from '../types.js';
import { parseAppLanguage, type AppLanguage } from './app-language.js';
import { parsePersonality, type ChatPersonality } from './chat-style.js';
import { parseDepth, parseSpoken, type ChatDepth } from './chat-depth.js';
import { parseOrVoiceId, type OrVoiceId } from './or-voice.js';
import { parseOrSpeechSpeed, type OrSpeechSpeed } from './or-speech-speed.js';
import { parseTurns, type ChatTurn } from './parse-turns.js';
import { asRecord, sanitizeText, stringList } from './sanitize.js';
import type { SoulmateIdentity } from './soulmate-prompt.js';
import {
  validateNarrativeTarotPayload,
  type NarrativeTarotValidated,
} from './narrative-tarot-contract.js';
import {
  validateYildiznameNarrativePayload,
  type YildiznameNarrativeValidated,
} from './narrative-yildizname-contract.js';

type BaseRequest =
  | {
      operation: 'chat';
      userMessage: string;
      priorUser: string[];
      turns: ChatTurn[];
      personality?: ChatPersonality;
      styleHint?: string;
      depth?: ChatDepth;
      spoken?: boolean;
    }
  | {
      operation: 'oracle';
      userMessage: string;
      priorUser: string[];
      turns: ChatTurn[];
      personality?: ChatPersonality;
      styleHint?: string;
      depth?: ChatDepth;
      spoken?: boolean;
      kind: OracleKind;
      context: Record<string, unknown>;
    }
  | { operation: 'dream_analysis'; payload: Record<string, unknown> }
  | { operation: 'coffee_analysis'; payload: Record<string, unknown> }
  | { operation: 'palm_analysis'; payload: Record<string, unknown> }
    | {
      operation: 'soulmate_draw';
      name: string;
      birthDate: string;
      gender?: 'feminine' | 'masculine';
      intention?: string;
    }
    | {
      operation: 'soulmate_interpretation';
      name: string;
      birthDate: string;
      gender?: 'feminine' | 'masculine';
      intention?: string;
      identity?: SoulmateIdentity;
      memorySummary?: string;
    }
  | {
      operation: 'tarot_reading';
      mode: 'legacy';
      cards: TarotCardInput[];
      spreadLabel: string;
      userQuestion?: string;
      readingTheme?: string;
      journeyHints?: TarotJourneyHints;
    }
  | NarrativeTarotValidated
  | YildiznameNarrativeValidated
  | {
      operation: 'tts';
      text: string;
      personality?: ChatPersonality;
      voiceId: OrVoiceId;
      speechSpeed: OrSpeechSpeed;
    };

export type ValidatedRequest = BaseRequest & { language: AppLanguage };

export function validateAiBody(body: unknown): ValidatedRequest {
  const record = asRecord(body);
  if (!record) fail(ErrorCode.invalidRequest);
  // Reject unknown top-level keys. Identity spoof fields are ignored (never trusted).
  const allowedTop = new Set([
    'operation',
    'payload',
    'model',
    'userId',
    'user_id',
    'uid',
    'sub',
  ]);
  for (const key of Object.keys(record)) {
    if (!allowedTop.has(key)) fail(ErrorCode.invalidRequest);
  }
  // userId / user_id / sub in the body are ignored. Identity comes only
  // from verified Authorization. Never trust client-supplied user ids.
  const operation = record.operation;
  if (typeof operation !== 'string' || !OPERATIONS.includes(operation as AiOperation)) {
    fail(ErrorCode.invalidRequest);
  }
  const payload = asRecord(record.payload) ?? {};
  const language = parseAppLanguage(payload.language);
  switch (operation as AiOperation) {
    case 'chat':
      return { ...validateChat(payload), language };
    case 'oracle':
      return { ...validateOracle(payload), language };
    case 'dream_analysis':
      return { ...validateDream(payload), language };
    case 'coffee_analysis':
      return { operation: 'coffee_analysis', payload, language };
    case 'palm_analysis':
      return { operation: 'palm_analysis', payload, language };
    case 'soulmate_draw':
      return { ...validateSoulMate(payload), language };
    case 'soulmate_interpretation':
      return { ...validateSoulMateInterpretation(payload), language };
    case 'tarot_reading':
      return { ...validateTarot(payload), language };
    case 'yildizname_reading':
      return { ...validateYildiznameNarrativePayload(payload), language };
    case 'tts':
      return { ...validateTts(payload), language };
  }
}

export type TarotCardInput = {
  name: string;
  positionLabel: string;
  reversed: boolean;
  meaning: string;
  keywords: string[];
};

export type TarotJourneyHints = {
  recurringThemes: string[];
  recentCardNames: string[];
  priorReadingCount: number;
  revisitExcerpt?: string;
  memorySummary?: string;
};

const CARD_MAX = 12;

function validateTarot(
  payload: Record<string, unknown>,
): Extract<BaseRequest, { operation: 'tarot_reading' }> {
  if (payload.mode === undefined || payload.mode === null) {
    return validateLegacyTarot(payload);
  }
  if (payload.mode === 'narrative_v2') {
    return validateNarrativeTarotPayload(payload);
  }
  fail(ErrorCode.invalidRequest);
}

function validateLegacyTarot(
  payload: Record<string, unknown>,
): Extract<BaseRequest, { operation: 'tarot_reading'; mode: 'legacy' }> {
  const rawCards = Array.isArray(payload.cards) ? payload.cards : [];
  const cards: TarotCardInput[] = [];
  for (const raw of rawCards.slice(0, CARD_MAX)) {
    const record = asRecord(raw);
    if (!record) continue;
    const name = sanitizeText(record.name, 80);
    const positionLabel = sanitizeText(record.positionLabel, 80);
    if (!name || !positionLabel) continue;
    cards.push({
      name,
      positionLabel,
      reversed: record.reversed === true,
      meaning: sanitizeText(record.meaning, 400),
      keywords: stringList(record.keywords, 8),
    });
  }
  if (cards.length === 0) fail(ErrorCode.invalidRequest);
  const spreadLabel = sanitizeText(payload.spreadLabel, 80);
  if (!spreadLabel) fail(ErrorCode.invalidRequest);
  const userQuestion = sanitizeText(payload.userQuestion, 400);
  const readingTheme = sanitizeText(payload.readingTheme, 80);
  const hintsRecord = asRecord(payload.journeyHints);
  const journeyHints: TarotJourneyHints | undefined = hintsRecord
    ? {
        recurringThemes: stringList(hintsRecord.recurringThemes, 5),
        recentCardNames: stringList(hintsRecord.recentCardNames, 5),
        priorReadingCount:
          typeof hintsRecord.priorReadingCount === 'number'
            ? Math.max(0, Math.floor(hintsRecord.priorReadingCount))
            : 0,
        revisitExcerpt: sanitizeText(hintsRecord.revisitExcerpt, 240) || undefined,
        memorySummary: sanitizeText(hintsRecord.memorySummary, 220) || undefined,
      }
    : undefined;
  return {
    operation: 'tarot_reading',
    mode: 'legacy',
    cards,
    spreadLabel,
    userQuestion: userQuestion || undefined,
    readingTheme: readingTheme || undefined,
    journeyHints,
  };
}

function validateChat(payload: Record<string, unknown>): Extract<BaseRequest, { operation: 'chat' }> {
  const userMessage = sanitizeText(payload.userMessage);
  if (userMessage.length < 2) fail(ErrorCode.invalidRequest);
  const styleHint = sanitizeText(payload.styleHint, 360);
  return {
    operation: 'chat',
    userMessage,
    priorUser: stringList(payload.priorUser, 8),
    turns: parseTurns(payload.turns, 8),
    personality: parsePersonality(payload.personality),
    styleHint: styleHint || undefined,
    depth: parseDepth(payload.depth),
    spoken: parseSpoken(payload.spoken),
  };
}

function validateOracle(payload: Record<string, unknown>): Extract<BaseRequest, { operation: 'oracle' }> {
  const userMessage = sanitizeText(payload.userMessage);
  if (userMessage.length < 2) fail(ErrorCode.invalidRequest);
  const context = asRecord(payload.context);
  if (!context) fail(ErrorCode.invalidRequest);
  const kind = context.kind;
  if (typeof kind !== 'string' || !ORACLE_KINDS.includes(kind as OracleKind)) {
    fail(ErrorCode.invalidRequest);
  }
  assertOracleFields(kind as OracleKind, context);
  const styleHint = sanitizeText(payload.styleHint, 360);
  return {
    operation: 'oracle',
    userMessage,
    priorUser: stringList(payload.priorUser, 8),
    turns: parseTurns(payload.turns, 8),
    personality: parsePersonality(payload.personality),
    styleHint: styleHint || undefined,
    depth: parseDepth(payload.depth),
    spoken: parseSpoken(payload.spoken),
    kind: kind as OracleKind,
    context,
  };
}

function validateSoulMate(
  payload: Record<string, unknown>,
): Extract<BaseRequest, { operation: 'soulmate_draw' }> {
  const name = sanitizeText(payload.name, 80);
  const birthDate = sanitizeText(payload.birthDate, 16);
  if (name.length < 2 || !/^\d{4}-\d{2}-\d{2}$/.test(birthDate)) {
    fail(ErrorCode.invalidRequest);
  }
  const genderRaw = sanitizeText(payload.gender, 16);
  const gender =
    genderRaw === 'feminine' || genderRaw === 'masculine'
      ? genderRaw
      : undefined;
  const intention = sanitizeText(payload.intention, 200);
  return {
    operation: 'soulmate_draw',
    name,
    birthDate,
    gender,
    intention: intention || undefined,
  };
}

function validateSoulMateInterpretation(
  payload: Record<string, unknown>,
): Extract<BaseRequest, { operation: 'soulmate_interpretation' }> {
  const base = validateSoulMate(payload);
  return {
    operation: 'soulmate_interpretation',
    name: base.name,
    birthDate: base.birthDate,
    gender: base.gender,
    intention: base.intention,
    identity: parseSoulmateIdentity(payload.identity),
    memorySummary: sanitizeText(payload.memorySummary, 220) || undefined,
  };
}

function parseSoulmateIdentity(raw: unknown): SoulmateIdentity | undefined {
  const record = asRecord(raw);
  if (!record) return undefined;
  const nonce = sanitizeText(record.nonce, 32);
  const presence = sanitizeText(record.presence, 80);
  const mood = sanitizeText(record.mood, 80);
  if (!nonce || !presence || !mood) return undefined;
  const versionRaw = Number(record.version);
  return {
    version: Number.isFinite(versionRaw) && versionRaw > 0 ? versionRaw : 1,
    nonce,
    presence,
    colorFamily: sanitizeText(record.colorFamily, 120),
    mood,
    setting: sanitizeText(record.setting, 180),
    lighting: sanitizeText(record.lighting, 180),
    wardrobe: sanitizeText(record.wardrobe, 180),
    composition: sanitizeText(record.composition, 180),
    pose: sanitizeText(record.pose, 160),
    expression: sanitizeText(record.expression, 160),
    ageBand: sanitizeText(record.ageBand, 40),
    faceShape: sanitizeText(record.faceShape, 80),
    hairFamily: sanitizeText(record.hairFamily, 80),
    eyePresentation: sanitizeText(record.eyePresentation, 80),
    relationshipArchetype: sanitizeText(record.relationshipArchetype, 80),
    expressionEnergy: sanitizeText(record.expressionEnergy, 80),
    stylingEnergy: sanitizeText(record.stylingEnergy, 80),
  };
}

function validateTts(
  payload: Record<string, unknown>,
): Extract<BaseRequest, { operation: 'tts' }> {
  const text = sanitizeText(payload.text, 1200);
  if (text.length < 1) fail(ErrorCode.invalidRequest);
  return {
    operation: 'tts',
    text,
    personality: parsePersonality(payload.personality),
    voiceId: parseOrVoiceId(payload.voiceId),
    speechSpeed: parseOrSpeechSpeed(payload.speechSpeed),
  };
}

function validateDream(payload: Record<string, unknown>): Extract<BaseRequest, { operation: 'dream_analysis' }> {
  const narrative = sanitizeText(payload.narrative);
  if (narrative.length < 8) fail(ErrorCode.invalidRequest);
  return {
    operation: 'dream_analysis',
    payload: {
      ...payload,
      narrative,
      memorySummary: sanitizeText(payload.memorySummary, 220) || undefined,
    },
  };
}

function assertOracleFields(kind: OracleKind, context: Record<string, unknown>): void {
  const need = (key: string) => {
    if (!sanitizeText(context[key])) fail(ErrorCode.invalidRequest);
  };
  switch (kind) {
    case 'tarot':
      need('cardsSummary');
      break;
    case 'dream':
      need('narrative');
      break;
    case 'astrology':
      need('signLabel');
      need('daily');
      break;
    case 'birthChart':
      need('sunLabel');
      need('interpretation');
      break;
    case 'coffee':
      need('overall');
      break;
    case 'palm':
      need('overall');
      break;
  }
}
