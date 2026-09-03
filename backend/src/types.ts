import type { FastifyRequest } from 'fastify';

export type AiOperation =
  | 'chat'
  | 'oracle'
  | 'dream_analysis'
  | 'coffee_analysis'
  | 'palm_analysis'
  | 'soulmate_draw'
  | 'tts';

export const OPERATIONS: readonly AiOperation[] = [
  'chat',
  'oracle',
  'dream_analysis',
  'coffee_analysis',
  'palm_analysis',
  'soulmate_draw',
  'tts',
] as const;

export type OracleKind =
  | 'tarot'
  | 'dream'
  | 'astrology'
  | 'birthChart'
  | 'coffee'
  | 'palm';

export const ORACLE_KINDS: readonly OracleKind[] = [
  'tarot',
  'dream',
  'astrology',
  'birthChart',
  'coffee',
  'palm',
] as const;

export type OpenAiMessage = {
  role: 'system' | 'user' | 'assistant';
  content: string | OpenAiContentPart[];
};

export type OpenAiContentPart =
  | { type: 'text'; text: string }
  | { type: 'image_url'; image_url: { url: string; detail?: 'low' | 'high' | 'original' | 'auto' } };

export type OpenAiFetch = typeof fetch;

declare module 'fastify' {
  interface FastifyRequest {
    requestId: string;
    identityKey: string;
    authSubject: string;
  }
}

export type AuthedRequest = FastifyRequest;
