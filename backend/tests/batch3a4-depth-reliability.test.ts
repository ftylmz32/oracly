/**
 * BATCH 3A.4 — coffee insight diversity and palm contract satisfiability.
 */

import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import {
  coffeeInsightCollapse,
  evaluateCoffeeQuality,
  evaluatePalmQuality,
} from '../src/ai/human-quality.js';
import { bindCoffeeNarrative, bindPalmNarrative } from '../src/ai/reading/evidence-bind.js';
import {
  coffeeWriterSystem,
  palmWriterSystem,
  repairWriterSystem,
} from '../src/ai/reading/writer-prompts.js';
import type { CoffeeNarrative, PalmNarrative } from '../src/ai/reading/types.js';

function load(name: string) {
  return JSON.parse(readFileSync(`./tests/fixtures/batch3a/${name}.json`, 'utf8'));
}

function coffeeInput(n: CoffeeNarrative) {
  return {
    visualObservation: n.visualObservation.text,
    overall: n.overall.text,
    love: n.love.text,
    career: n.career.text,
    money: n.money.text,
    nearFuture: n.nearFuture.text,
    takeaway: n.takeaway.text,
    language: 'tr' as const,
  };
}

describe('BATCH 3A.4 — coffee diversity', () => {
  it('rejects the live 3A.3 reading as one idea paraphrased across sections', () => {
    const live = load('coffee_live_3a3');
    const n = live.narrative as CoffeeNarrative;
    expect(coffeeInsightCollapse(n.overall.text, n.nearFuture.text, n.takeaway.text)).toBe(true);
    expect(evaluateCoffeeQuality(coffeeInput(n))).toBe('section_redundancy');
  });

  it('accepts the same cup facts when insights stay additive and unthemed', () => {
    const good = load('coffee_diverse_3a4');
    expect(evaluateCoffeeQuality(coffeeInput(good.narrative))).toBeNull();
    expect(bindCoffeeNarrative(good.narrative, good.observation, 'tr', {
      firstName: 'Fatih',
    })).toBeNull();
  });

  it('writer asks for additive coffee insights and a short caption', () => {
    const prompt = coffeeWriterSystem('tr');
    expect(prompt).toContain('ADDITIVE insights');
    expect(prompt).toContain('short secondary caption');
  });
});

describe('BATCH 3A.4 — palm contract and targeted repair', () => {
  it('line geometry stays in line sections; synthesis does not restate it', () => {
    const good = load('palm_good_3a3');
    const n = good.narrative as PalmNarrative;
    expect(evaluatePalmQuality({
      visualObservation: n.visualObservation.text,
      overall: n.overall.text,
      lifeLine: n.lifeLine.text,
      headLine: n.headLine.text,
      heartLine: n.heartLine.text,
      fateLine: n.fateLine.text,
      takeaway: n.takeaway.text,
      language: 'tr',
      trustedHandSide: true,
    })).toBeNull();
    expect(bindPalmNarrative(n, good.observation, 'tr', true, {
      firstName: 'Fatih',
    })).toBeNull();
  });

  it('repair guidance for evidence_reuse names the structural fix', () => {
    const repair = repairWriterSystem('palm');
    expect(repair).toContain('If evidence_reuse');
    expect(repair).toContain('Leave length, direction, depth, curve, and continuity');
    expect(palmWriterSystem('tr')).toContain('Never fabricate fateLine');
    expect(palmWriterSystem('tr')).toContain('must not re-describe the same length');
  });
});
