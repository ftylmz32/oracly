import type { AppLanguage } from '../src/ai/app-language.js';
import type { DreamAcceptanceFailure, DreamAcceptanceInput } from '../src/ai/dream-acceptance.js';
import type { DreamData } from '../src/ai/parse-provider.js';

/** One synthetic premium-quality case — no real user content, no provider prose. */
export type CorpusCase = {
  id: string;
  input: DreamAcceptanceInput;
  data: DreamData;
  expect: DreamAcceptanceFailure | null;
};

export type CorpusBase = { input: DreamAcceptanceInput; data: DreamData };

export function base(
  language: AppLanguage,
  narrative: string,
  data: DreamData,
  extra: Partial<DreamAcceptanceInput> = {},
): CorpusBase {
  return { input: { narrative, symbols: [], emotions: [], language, ...extra }, data };
}

export function good(id: string, b: CorpusBase, patch: Partial<DreamData> = {}, input: Partial<DreamAcceptanceInput> = {}): CorpusCase {
  return { id, input: { ...b.input, ...input }, data: { ...b.data, ...patch }, expect: null };
}

export function bad(
  id: string,
  b: CorpusBase,
  expect: DreamAcceptanceFailure,
  patch: Partial<DreamData>,
  input: Partial<DreamAcceptanceInput> = {},
): CorpusCase {
  return { id, input: { ...b.input, ...input }, data: { ...b.data, ...patch }, expect };
}
