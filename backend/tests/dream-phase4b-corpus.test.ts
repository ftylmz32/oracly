import { describe, expect, it } from 'vitest';
import type { AppLanguage } from '../src/ai/app-language.js';
import { dreamAcceptanceFailure } from '../src/ai/dream-acceptance.js';
import { enCorpus } from './dream-phase4b-corpus-en.js';
import { ruCorpus } from './dream-phase4b-corpus-ru.js';
import { trCorpus } from './dream-phase4b-corpus-tr.js';
import type { CorpusCase } from './dream-phase4b-corpus-types.js';

const corpora: Record<string, CorpusCase[]> = { en: enCorpus, tr: trCorpus, ru: ruCorpus };

describe('Dream Phase 4B — premium quality corpus', () => {
  for (const [language, cases] of Object.entries(corpora)) {
    it(`${language}: ≥15 GOOD and ≥30 BAD, all unique ids`, () => {
      expect(cases.filter((c) => c.expect === null).length).toBeGreaterThanOrEqual(15);
      expect(cases.filter((c) => c.expect !== null).length).toBeGreaterThanOrEqual(30);
      expect(new Set(cases.map((c) => c.id)).size).toBe(cases.length);
      expect(cases.every((c) => c.input.language === (language as AppLanguage))).toBe(true);
    });

    for (const c of cases) {
      it(`${c.id} → ${c.expect ?? 'accepted'}`, () => {
        expect(dreamAcceptanceFailure(c.data, c.input)).toBe(c.expect);
      });
    }
  }
});
