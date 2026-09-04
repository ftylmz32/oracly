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
import {
  validateTarotAnalysisPayload,
  type TarotAnalysisInput,
} from './tarot-reading.js';

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
  | { operation: 'tarot_analysis'; payload: TarotAnalysisInput }
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
    case 'tarot_analysis':
      return {
        operation: 'tarot_analysis',
        payload: validateTarotAnalysisPayload(payload),
        language,
      };
    case 'dream_analysis':
      return { ...validateDream(payload), language };
    case 'coffee_analysis':
      return { operation: 'coffee_analysis', payload, language };
    case 'palm_analysis':
      return { operation: 'palm_analysis', payload, language };
    case 'soulmate_draw':
      return { ...validateSoulMate(payload), language };
    case 'tts':
      return { ...validateTts(payload), language };
  }
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
  return { operation: 'dream_analysis', payload };
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
