/**
 * Phase 6E.5 — Writing-quality prompt contract + QA distinctness regression.
 * Does NOT call providers. Does NOT modify historical 6E.4.2 fixtures.
 */
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import {
  memoryIndexLegend,
  narrativeSystemRules,
  resultContractDirective,
} from '../src/ai/narrative-tarot-prompt-rules.js';
import { narrativeTarotMessages } from '../src/ai/narrative-tarot-prompts.js';

const RESULTS_6E42 = resolve(
  process.cwd(),
  '../test/fixtures/tarot_narrative_provider_shadow_results_6e42_v2.json',
);

function rulesText(): string {
  return narrativeSystemRules().join('\n');
}

describe('Phase 6E.5 writing-quality prompt contract', () => {
  it('preserves Result Contract V2 + memoryIndices directives', () => {
    const d = resultContractDirective();
    expect(d).toMatch(/Version 2/);
    expect(d).toMatch(/memoryIndices/);
    expect(d).toMatch(/Do not emit memoryIndex/);
  });

  it('keeps prophecy / future modality rules (Q1)', () => {
    const r = rulesText();
    expect(r).toMatch(/possibility|trajectory|invitation/i);
    expect(r).toMatch(/will definitely|will certainly|guaranteed/i);
    expect(r).toMatch(/may \/ could/i);
  });

  it('requires direct-answer summary (no boilerplate openers)', () => {
    const r = rulesText();
    expect(r).toMatch(/DIRECT ANSWER/i);
    expect(r).toMatch(/This reading shows\/highlights/i);
    expect(r).toMatch(/summary:.*concise/i);
  });

  it('relationship safety ≠ evasion + reflective framing', () => {
    const r = rulesText();
    expect(r).toMatch(/No mind-reading does NOT mean refusing/i);
    expect(r).toMatch(/spread may reflect/i);
    expect(r).toMatch(/расклад может отражать/i);
    expect(r).toMatch(/sembolik olarak/i);
    expect(r).toMatch(/SYMBOLICALLY/i);
  });

  it('locks distinct section responsibilities', () => {
    const r = rulesText();
    expect(r).toMatch(/cardReadings:/i);
    expect(r).toMatch(/synthesis:.*tension/i);
    expect(r).toMatch(/relationshipInsights:/i);
    expect(r).toMatch(/recurringCardInsights:/i);
    expect(r).toMatch(/recurringThemeInsights:/i);
    expect(r).toMatch(/memoryInsights:/i);
    expect(r).toMatch(/lifeAreas:/i);
    expect(r).toMatch(/advice:/i);
    expect(r).toMatch(/reflectionPrompt:/i);
    expect(r).toMatch(/dailyFocus:/i);
    expect(r).toMatch(/closingMessage:/i);
  });

  it('requires single-card compression + optional non-padding', () => {
    const r = rulesText();
    expect(r).toMatch(/Single-card spreads must stay compact/i);
    expect(r).toMatch(/Empty optional content is better than filler/i);
    expect(r).toMatch(/lifeAreas are optional/i);
    expect(r).toMatch(/return \[\]/i);
  });

  it('calibrates recurrence frequency for count=2', () => {
    const r = rulesText();
    expect(r).toMatch(/occurrenceCount = 2/i);
    expect(r).toMatch(/appeared twice|has reappeared|appeared again/i);
    expect(r).toMatch(/persistent pattern/i);
  });

  it('requires semantic/native rewrite + TR/RU/EN naturalness', () => {
    const r = rulesText();
    expect(r).toMatch(/semantic authority/i);
    expect(r).toMatch(/Rewrite idiomatically/i);
    expect(r).toMatch(/TR: natural contemporary Turkish/i);
    expect(r).toMatch(/RU: idiomatic contemporary Russian/i);
    expect(r).toMatch(/указывает на/);
    expect(r).toMatch(/EN: avoid stock AI\/Tarot filler/i);
    expect(r).toMatch(/embrace the journey/i);
  });

  it('non-generic closing rule', () => {
    const r = rulesText();
    expect(r).toMatch(/closingMessage:.*SPECIFIC/i);
    expect(r).toMatch(/embrace the journey/i);
    expect(r).toMatch(/generic blessing/i);
  });

  it('memory legend still lists indices', () => {
    const legend = memoryIndexLegend({
      memory: {
        included: true,
        priorReadingCount: 2,
        entries: [
          { kind: 'memorySummary', contentForModel: 'a' },
          { kind: 'memorySummary', contentForModel: 'b' },
        ],
      },
    } as never);
    expect(legend).toContain('Memory 0');
    expect(legend).toContain('Memory 1');
    expect(legend).toMatch(/memoryIndices/);
  });

  it('composed system prompt still embeds rules', () => {
    const msgs = narrativeTarotMessages(
      {
        memory: { included: false, priorReadingCount: 0, entries: [] },
      } as never,
      'en',
    );
    const joined = msgs.map((m) => m.content).join('\n');
    expect(joined).toMatch(/DIRECT ANSWER/i);
    expect(joined).toMatch(/Single-card spreads must stay compact/i);
    expect(joined).toMatch(/Version 2/);
  });
});

describe('Phase 6E.5 QA section distinctness on immutable 6E.4.2 results', () => {
  it('flags high/review repetition on calls #3/#4/#6 without modifying fixture', async () => {
    const raw = readFileSync(RESULTS_6E42, 'utf8');
    const root = JSON.parse(raw) as {
      calls: Array<{
        callNumber: number;
        repetitionObservation?: string;
        structuredResult?: Record<string, unknown>;
      }>;
    };

    const byNum = (n: number) => root.calls.find((c) => c.callNumber === n)!;
    expect(byNum(3).repetitionObservation).toBe('repetitive');
    expect(byNum(4).repetitionObservation).toBe('repetitive');
    expect(byNum(6).repetitionObservation).toBe('repetitive');
    expect(byNum(1).repetitionObservation).toBe('distinct');
    expect(byNum(2).repetitionObservation).toBe('distinct');
    expect(byNum(5).repetitionObservation).toBe('distinct');

    // QA-only diagnostic (tool/qa) — not a production gate.
    // Lexical Jaccard surfaces some cases; thematic synonym repetition (ChatGPT
    // #4/#6) may remain "low" by token overlap — do NOT overfit a threshold.
    const toolPath = resolve(
      process.cwd(),
      '../tool/qa/narrative_section_distinctness.mjs',
    );
    const { diagnoseResults } = await import(toolPath);
    const report = diagnoseResults(root);
    expect(report.productionGate).toBe(false);
    expect(report.overallQualityScore).toBeNull();
    expect(report.calls).toHaveLength(6);
    expect(report.calls.every((c: { overlaps: object }) => !!c.overlaps)).toBe(
      true,
    );
    // Call #3 advice↔closing lexical overlap is elevated in the capture.
    const c3diag = report.calls.find(
      (c: { callNumber: number }) => c.callNumber === 3,
    );
    expect(c3diag.maxOverlap).toBeGreaterThan(0.25);

    // Call #4 future modality preserved in captured prose (Q1 regression lesson).
    const c4 = JSON.stringify(byNum(4).structuredResult);
    expect(c4).toMatch(/possibility|potential|could|achievable/i);
    expect(c4).not.toMatch(/will definitely|will certainly|future promises/i);

    // Call #6 memoryIndices contract preserved.
    const mem =
      (byNum(6).structuredResult?.memoryInsights as Array<{
        memoryIndices: number[];
      }>) ?? [];
    expect(mem.some((m) => JSON.stringify(m.memoryIndices) === '[0,1]')).toBe(
      true,
    );

    // Fixture immutability: re-read must match original bytes for this path.
    const raw2 = readFileSync(RESULTS_6E42, 'utf8');
    expect(raw2).toBe(raw);
  });
});
