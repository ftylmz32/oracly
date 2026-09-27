import { describe, expect, it } from 'vitest';
import { dreamAcceptanceFailure } from '../src/ai/dream-acceptance.js';
import { enCorpus } from './dream-phase4b-corpus-en.js';
import { ruCorpus } from './dream-phase4b-corpus-ru.js';
import { trCorpus } from './dream-phase4b-corpus-tr.js';

const EVALUATIONS = 3000;

describe('Dream Phase 4B — acceptance cost', () => {
  it(`runs ${EVALUATIONS} full acceptance evaluations deterministically and fast`, () => {
    const cases = [...enCorpus, ...trCorpus, ...ruCorpus];
    const started = performance.now();
    for (let i = 0; i < EVALUATIONS; i++) {
      const c = cases[i % cases.length]!;
      expect(dreamAcceptanceFailure(c.data, c.input)).toBe(c.expect);
    }
    const totalMs = performance.now() - started;
    const avgMs = totalMs / EVALUATIONS;
    console.info(`[dream-4b-perf] evaluations=${EVALUATIONS} totalMs=${totalMs.toFixed(1)} avgMs=${avgMs.toFixed(3)}`);
    expect(avgMs).toBeLessThan(5);
  });
});
